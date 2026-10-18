# Variant · Client State Library

<!--
GENERATOR NOTES — delete this block in the emitted file.

**This is a delta, not a replacement.** `data-and-state.md` §Server State vs UI
State already decides *where* each kind of state lives; this variant decides
*which library* holds the client-owned state. The decision rules — the search
rule, the mutation rule, the invalidation rules — are identical regardless of
which library is chosen, and are not restated here.

Status: doc-sourced. No audited project in the source set used the non-default
options; the rules below are mechanism-level and traceable to each library's
documentation. Verify the API surface against the installed version.

**The most important row is the first one.** Every project that has drifted into
two state mechanisms has drifted by adding the second one for a single feature
"just this once".

**Why this is a variant and not a tech overlay, and why it is not shorter than
it looks.** It is a variant because the *choice* is an axis — the same project
shape can use any of these — and because the decision rules it depends on already
live in `data-and-state.md` and are not restated. It is four concerns, not one:
which library, the six rules that hold whichever is chosen, the decision to add
one at all, and the store-specific testing rules. An audit pass proposed cutting
it to roughly a quarter of its length on the grounds that "96 lines is a lot for
one decision"; that would have removed the six universal rules and the testing
section, neither of which is a restatement of anything. Kept whole, with this
note so the next pass doesn't raise it again.
-->

# Applying a Client State Library

Apply when the project has a client-owned state library beyond component-local
state. **This is not the server-state layer** — if the project uses a
server-state/cache library, that choice is made in `data-and-state.md` and
`tech/`, not here. The two are different concerns and conflating them is the
most common architectural confusion in this family of stacks.

## The selection

| Library | Shape | Fits when |
|---|---|---|
| Component state only | `useState` / `useReducer` / a framework equivalent | The project genuinely has no cross-component client state. **This is a legitimate and common answer** — a small app with server state in a cache library and nothing else client-side needs no store |
| A single store with slices and middleware | {{Redux Toolkit and equivalents}} | Several unrelated slices of client state, a need to inspect or replay state transitions, a large team sharing conventions, or middleware — persistence, logging, analytics — driven off state changes |
| A minimal observable store | {{Zustand and equivalents}} | A small amount of genuinely global client state, with no need for slices, middleware, or devtools-driven convention |
| A reducer plus context | `useReducer` + provider | State shared by a subtree, no cross-cutting writes, no tooling need |

**Whatever is chosen, one library.** Two state mechanisms coexist only when the
boundary between them is written down — and "a feature used the other one once"
is not a boundary.

## Rules that apply to every choice

- **Server data does not live here.** This library holds what the user is
  *doing*, not what the server *said*. A response body in a global store, next to
  a cache that already owns it, is two sources of truth with different
  lifetimes.
- **The store is not a place to put things that don't need sharing.** Local
  state that happens to be in a global store is a component that re-renders
  because something unrelated changed.
- **Mutations are named operations, not scattered assignments.** A thunk, an
  action creator, or a store method — but one named, callable operation per
  intent, callable from a component as `{{store.doThing()}}`. **A component
  that assembles a multi-step state update inline is putting logic in the view.**
- **The library's typed hooks only, never the raw library's hooks.** A raw hook
  is untyped against the store's state and loses the type checking that makes the
  store worth having.
- **Selectors, not whole-state reads,** where the library supports them. A
  component subscribing to the whole store re-renders on every change.
- **Persistence is explicit.** If state is persisted across sessions, it is
  declared — what is persisted, what is cleared on logout, and what version the
  stored shape is. **Logout clears persisted state** (`core/security.md`
  §Session Teardown); a store that survives a sign-out is a data leak.
- **The store's shape is versioned if it's persisted.** A stored shape that
  changes between releases needs a migration or a reset — a store that fails to
  parse on a schema change breaks the app on launch.

## Adding this library at all

**Adding a global store is a decision, not a convenience**
(`data-and-state.md` §Server State vs UI State). Before adding one:

- **Name the concrete need** it solves that local state plus the server-state
  layer cannot. "It could be useful later" is not a need.
- **Write it in the decisions log** with what was rejected and why. This is the
  rule from the source material that both audited projects stated independently,
  and it is the one that stops the migration from being repeated.
- **Confirm the existing need isn't the server-state layer wearing the wrong
  hat.** Most "we need a global store" conclusions are actually "we need
  server-state caching" or "we need a reducer".

## Testing

The rules in `testing.md` apply. The store-specific addition:

- **Test a store's operation, not its reducer's shape** where the library
  exposes an operation. Assert that dispatching the operation produces the
  intended state transition from a realistic initial state.
- **A store test sets up realistic state, not an empty object.** A reducer that
  assumes a populated slice passes every test against `{}` and fails on the
  first real dispatch.
- **A middleware or persistence concern is tested directly**, including the
  logout-clears-state case.
- Never: assert on the library's internal action log as the test's only
  assertion; test a reducer against a hand-built state that the real app never
  produces.
