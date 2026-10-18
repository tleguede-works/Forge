# Template · Data Access & State

<!--
GENERATOR NOTES — delete this block in the emitted file.

Owns: how data is reached, where it lives, how it is invalidated, and the two
decision rules that were duplicated across every audited project — search
(debounce vs submit) and mutations (optimistic vs wait-for-response).

The mechanism differs per stack; the rules do not. What goes in the tech overlay
is the client library, the cache-key syntax, and the two library-specific
function names. What stays here is the decision logic.

The single highest-value merge in this library: four separate copies of the
search rules and three of the mutation rules across three projects, including one
project that duplicated its own search rules across two files. All of it lives
here, once.

Not owned here: error *shape* (errors-and-loading-states.md), form validation
(forms.md), secret handling (security.md), route definitions (architecture.md).
-->

# Data Access & State Rules

## The Mandatory Access Shape

```
{{UI layer}}  →  {{hook / controller}}  →  {{data layer: client + query + normalizer}}
```

- **The UI layer never calls the data layer directly** — not a client, not
  `fetch`, not a query builder, not an ORM session. Only through the middle
  layer.
  - Verify: `{{grep}}` returns empty.
- **The middle layer never contains a raw query string.** It composes the
  data-layer's exported operations and normalizes the result.
- **If a component needs data no {{hook}} provides, write the hook.** Don't
  reach for a raw call inline "just this once" — that is how the bypass starts.
- {{e.g. one hook per entity, in one place: `useProducts`, `useProduct(handle)`,
  `useCart`.}}

## The Single Client

- **One configured client instance**, in one module, created once and exported
  once. It carries the base URL, auth, error normalisation, and timeouts.
- **Never a second instance with different config. Never a raw `fetch` against
  an endpoint the configured client already covers.** A second client silently
  loses the interceptors, and the bug surfaces as a missing auth header three
  files away.
- **Read configuration once, fail loudly at startup if a required value is
  missing.** Do not ship a dead client that fails on first use.
- {{e.g. a single hardcoded API version constant, in the config module.
  A version string appearing more than once in the codebase is a violation.}}

## Server State vs UI State

**The distinction, once, correctly:**

| State | Where it lives |
|---|---|
| Anything fetched from the server, or derived from it | the server-state layer — a query/cache hook, never `useState` |
| {{e.g. the authenticated session: tokens, user identity, expiry}} | the server-state layer + the secure store, via the single auth module — **never a context used as a store** |
| Form input in progress, before submit | local state, or a form library once one is adopted |
| Ephemeral view state — which tab, whether a sheet is open, a filter draft | local state |
| Theme / colour scheme | the theme module + the platform's own API |
| Read by many screens but not server data — {{e.g. recently viewed ids}} | a small explicit hook + persistence if it must survive a restart — **never a hand-rolled singleton store** |

- **No server data in local state.** If you reach for `useState` to hold an API
  result, you need a query hook.
- **No global store unless a concrete need is proven** — and if it is proven,
  that is a new decision in the decisions log, not a library you add at the point
  of need. Do not start with one by default.
- {{e.g. auto-dispose page-scoped queries by default; keep-alive only by
  explicit choice.}}

## Cache Keys & Invalidation

- **Keys are hierarchical and defined in one module.** Never invented at a call
  site.
  - Shape: `['{{entity}}']`, `['{{entity}}', id]`, `['{{entity}}', id, '{{sub}}']`
- **Query hooks own their keys; mutations invalidate by prefix**
  (`invalidateQueries({{prefix}})`), never by guessing a full key.
- **Never put unbounded user input in a key** when a stable identifier exists —
  use the id or handle, not the search text.
- **Name the invalidation helper** for a cross-cutting case
  (`{{invalidateCustomerData()}}`) rather than scattering invalidation calls
  across screens.
- **Set a real global staleness default**, differentiated by data volatility:
  {{e.g. catalogue data caches long, cart and session data caches short}}.
  Don't leave everything at the library default, and don't set per-hook
  "always stale" reflexively. Leave the eviction/GC setting alone until a
  measured problem exists.
- Never: `{{clear the whole cache}}` to "refresh everything" as a fix; write to
  the cache outside a proper mutation pattern to make the UI feel faster;
  invalidate a key that no query owns.

## Search: Debounce vs Submit

**This is a decision rule, not a preference. Choose per search field, and say
which you chose.**

**Debounce** (300–500 ms) when the backend is fast and the result set is small:

- Cancel the previous timer on each keystroke; fire only after the user pauses.
- **Guard against a stale response.** A slow response for `"a"` must never
  overwrite results for `"ab"`. {{e.g. a request generation counter, or the
  cache layer's own key-change handling — last response wins.}}
- **Reset pagination and scroll to the top** whenever the criteria change.
  Results belong to the current filter.
- Show a loading state and an explicit empty state — **never the previous
  results** presented as the new results.

**Submit-driven** when the backend is slow, the query is expensive, or the
filter set is wide:

- Keep the draft selection in local state; commit on an explicit apply action.
- The same stale-response and pagination-reset rules apply.

> **Confirm the real latency before assuming either case.** "Lists are slow" is
> a guess. If you haven't measured, you haven't chosen — and the cost of the
> wrong choice is different in each direction.

## Mutations: Optimistic vs Wait-for-Response

**Choose deliberately per mutation. Never mix the two patterns for the same
mutation.**

**Wait-for-response** (the default) when:

- correctness matters more than instant feedback
- the operation has real consequences — a payment, a submission, anything the
  backend can reject for a business reason
- a rollback would confuse the user

Await the server; on success invalidate the affected queries; show a pending
state on the control that triggered it.

**Optimistic update** when:

- the action is low-stakes and high-frequency
- instant feedback is the core of the experience — a quantity stepper, a
  favourite toggle
- the rollback is simple and cheap

Apply to the cache immediately, **snapshot the previous value**, roll back on
error, revalidate when settled.

> **If genuinely unsure which fits: default to wait-for-response.** It is the
> safer failure mode — a slightly slower UI is a smaller problem than a
> confidently wrong one. Log the choice in the decisions log if it is significant
> enough that a future session would second-guess it.

**Rules that apply to both**

- **Never leave the cache lying.** An optimistic mutation always pairs its
  snapshot with a rollback and a revalidation. A mutation that can fail and
  doesn't roll back is a correctness bug, not a shortcut.
- **Mutate through the mutation hook only.** Never write to the cache directly
  to make the UI respond.
- **After a successful mutation that changes a list, the controls keep working**
  without a full reload. Invalidate; don't blind-refresh.
- **Mutations on the same entity are serial.** Don't fire two concurrent
  mutations against the same record — queue them, or disable the control while
  one is in flight.
- **Optimistic updates and concurrency control are not substitutes for a
  constraint check.** The server still validates.

## Mutation Success

**A 2xx response is not a successful mutation.** Many APIs return success at the
transport level while the operation itself failed in the payload.

- **Every mutation requests the payload's own error channel** and checks it. A
  mutation that can fail silently is a defect.
- **Check every error channel the response offers** — top-level errors,
  per-field errors on the payload, and any error code. "It returned 200" is not
  "it worked".
- **The normalizer is where a null becomes a fallback**, not in a screen. Keep
  nullability honest: a field that can be null in the source is a field the
  model admits, and the layer that reads the data decides what to do about it.

## Collections

- **A connection is a collection, not a list.** Keep the
  `{{edges { node }}}` + `{{pageInfo { hasNextPage endCursor }}}` shape in the
  data layer; flatten to a plain array only in the model, and expose
  `{{fetchMore}}` / `{{hasNextPage}}` from the data layer rather than
  hand-rolling page state in a component.
- **Never trust a single page.** If the endpoint is paginated, the caller must
  handle more than one.
- **Shared field selections are defined once** (fragments, DTO includes, select
  lists) next to the query. Repeating the same field list in six queries
  guarantees drift.

## Normalizers / Mappers

- **One function per model**, colocated with the model:
  `{{normalize<Model>(raw) → <Model>}}`.
- **Pure**: no side effects, no I/O, no async. A normalizer that fetches is a
  service wearing a normalizer's name.
- **Hand-written, explicit.** The value is that the mapping is visible and
  reviewable; a generated or magic-string mapper trades that for a build step.
- **The model type is declared once** and never re-declared as a parallel shape
  somewhere else.
- **Money is a structured value** — `{{amount, currencyCode}}` — never a bare
  number or a formatted string. Format at the edge, through one formatter.
- **A round-trip test** for every normalizer (`raw → model → raw`) — see
  `testing.md`.

## When Blocked

- **If the response shape is ambiguous or unexpected: stop, capture the exact
  response, report it against the shape you expected, and confirm the real shape
  before extending the normalizer.** Do not add a guess-based handler.
- **If a field you need does not exist: check the API/config version first, then
  the actual data.** Some fields are null until someone configures them
  server-side. Don't assume the API is wrong.
- **If the server-state library isn't installed yet, install it.** Don't fall
  back permanently to manual effect-and-state fetching.
- **If a constraint is undocumented** — a rate limit, a page size, a filter
  combination: confirm it against the real source, then encode it. Don't guess
  a threshold.
- Never: add a raw call to unblock a feature; widen a response type to
  `{{unknown}}` and read fields off it; treat an empty result as a success
  without checking the error channel.

## Canonical Example

Once `{{the first entity wired end-to-end: query + normalizer + hook}}` exists,
treat `{{path/to/that/file}}` as the reference for this pattern — reference it,
don't re-derive it, and don't paste its code here.
