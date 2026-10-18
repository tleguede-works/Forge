# Variant · SSR / Server-First Data Fetching

<!--
GENERATOR NOTES — delete this block in the emitted file.

**This is a delta, not a replacement.** It reverses a closed architectural
decision in the default variant, which makes it the highest-consequence variant
in the library. Applying it is not a configuration change.

Status: source-audited. Synthesised from the delta in the retired Next.js
profile; re-based onto the current overlay structure.

**Before generating with this variant, confirm the decision is actually closed
in favour of server-first fetching.** The default variant's rule is that the
backend is not called from Server Components. Reversing it changes where data
lives, which components are client components, and what the recovery surfaces
cover — three things that ripple through every other template.
-->

# Applying SSR / Server-First Data Fetching

Apply on top of `nextjs.md` when the backend is cleanly reachable from a Server
Component and the project has decided to fetch there.

**This is the right variant when** the backend is a plain REST or GraphQL API
reachable at build or request time, there is no auth or network complication
blocking a server-side call, and the project cares about first-paint or indexable
content.

**It is the wrong variant when** the backend can't be called from a server
context — a SOAP-wrapped legacy service, an internal gateway, anything behind
network segmentation — or when the project has decided on one data-fetching
mental model everywhere for consistency. In that case the default variant is
simpler and won't fight the constraint. **This is a question for the user, not
an inference from the framework.**

## The decision this reverses

The default variant's closed decision: *data fetching is client-side through one
configured HTTP client; the backend is not called from Server Components.*

**Applying this variant supersedes that decision.** It does not amend it.
Superseding a closed decision means a new entry in the decisions log that references
the one it replaces, and the old entry stays with a superseded marker
(`workflow.md` §Memory File Triggers).

**Two data-fetching strategies coexisting without a decision is the failure
mode this variant exists to prevent** — a codebase where some data comes from a
server component and some from a client effect, and nobody can say why. If the
project genuinely needs both — server-first for indexable pages, client-side for
authenticated interactive surfaces — that boundary is itself the decision, and
it belongs in the decisions log with the rule for which data goes where.

## Files that change

| In `nextjs.md` / `data-and-state.md` | Server-first instead |
|---|---|
| Data flows UI → hook → client | Data flows UI → **server function or loader** → backend. The client-side orchestration layer is for *client-owned* state only — optimistic updates, local interaction, subscriptions |
| The single HTTP client is called from the browser | The client is called from the server context. **The same single-instance rule holds**, and it holds harder: a second instance on the server is a second connection pool |
| Tokens live in browser-accessible storage | Session state is server-side. **The token never reaches the browser**, which changes `core/security.md` §Secret Scoping in the project's favour — say so explicitly rather than leaving the general rule to imply it |
| Cross-route data is fetched in a client effect | Cross-route data is fetched where the route is rendered, and passed down or accessed through the server-side mechanism |
| A Server Component is not a data-fetching component | **Reversed.** A Server Component is *the* data-fetching component |
| Cache invalidation from a client mutation | A mutation revalidates the server-side cache for the affected path, and returns the result to the client |
| The loading boundary is a file convention | Still a file convention, but it covers a server round trip — so it matters more, and a route with a slow server fetch needs one where the client variant wouldn't |
| Every data flow has loading/error/empty states | **Still required**, and the states are more visible: a server render either succeeds or throws. **An uncaught server-side error becomes an error boundary; a swallowed one becomes a blank page** — which is why the error handling rules apply with more force, not less |

## Rules that change

- **Authentication happens where the data is fetched.** A server-side fetch
  forwards the incoming request's credentials explicitly. A server fetch that
  silently runs *unauthenticated* because it couldn't see the browser's session
  is the characteristic bug of this variant, and its symptom is a page that
  renders successfully with empty data.
- **A mutation that changes server-rendered data must revalidate it.** A
  mutation that succeeds and leaves the server cache stale produces a UI that
  contradicts itself on the next navigation — and the fix is not a manual
  refresh, it is the revalidation.
- **The client-side cache-invalidation rules still apply to client-owned
  state** (`data-and-state.md` §Cache Invalidation). They are not replaced by
  server revalidation; they govern a different thing.
- **An optimistic update on server-rendered data is still an optimistic
  update** — applied to the client cache, rolled back on failure, revalidated on
  settle. The mutation rules do not change because the fetch moved.
- **Anything not serialisable cannot cross the server/client boundary.** This
  variant makes the boundary the primary architectural constraint, so the
  serialisation rule is enforced constantly rather than occasionally.
- **`{{"use client"}}` is pushed down harder than in the default variant.** Every
  component above a client boundary is a client component, and a client
  component in this variant forfeits server-side data access. The push-down rule
  is the same; the cost of getting it wrong is higher.

## Rules that survive unchanged

All of `accessibility.md`. `ui-components.md`. `performance.md` — including the
image, font, and script rows, which are server-rendering-relevant and unchanged.
`forms.md`, with the note that **client-side validation is now clearly UX only**,
since the boundary validation is on the server. `external-system-contracts.md`.
`core/coding-standards.md`.

## What this variant must not do

**Do not leave both strategies' rules in the emitted set.** The default
variant's "the backend is not called from Server Components" and this variant's
"a Server Component is the data-fetching component" cannot both be in the
project's rules. This is the single most likely half-application failure, which
is why the audit for a run that applied a variant includes a check that every
rule the variant reverses is actually gone.
