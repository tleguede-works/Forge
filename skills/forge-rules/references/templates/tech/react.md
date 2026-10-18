# Overlay · React

<!--
GENERATOR NOTES — delete this block in the emitted file.

Status: source-audited (one audited project, Next.js + React). The
boundary and composition rules generalise to any React; the rendering-mechanism
rows belong to `nextjs.md` where that overlay is emitted.

Emit alongside `core/coding-standards.md` and `domain/ui-components.md`.

**Provenance.** The composition and boundary rows come from the audited project
named above; the mechanism rows are React's documented behaviour and are
version-stable. The Named Footguns are the ones that move between React
versions — re-verify each against the installed version before emitting. When
this overlay is applied, the emitted file carries a `source:` marker on any rule
the project re-derived (`documentation-sources.md`).
-->

# React

## Component Boundaries

- **A component is a pure function of its props**, plus context. No data
  fetching in the component body, no subscription setup inline, no store
  access beyond a single read.
- **Effects are for synchronising with something outside React** — a subscription, a
  timer, an imperative handle, a network call. **They are not for deriving
  state**: if a value can be computed from props or state during render, compute
  it during render. An effect that sets state from other state causes an extra
  render pass on every change, and the extra pass is where the bugs live.
- **Never set state during render.** Derive instead.
- **Never call a mutating data function during render.** It fires on every
  render, including renders caused by Strict Mode's double-invoke.
- **A custom hook is the extraction point for anything reusable** — data access,
  a subscription, a form's coordination. Not a wrapper around two lines.

## Lists

- **Stable keys, never the index** (`performance.md` §Lists). Index keys turn a
  reorder into a remount: local state is lost and effects re-fire.
- **A key is required on every element in a list**, including static ones — a
  missing key is a warning now and a source of subtle bugs later.
- **The list's identity is its data, not its position.** Don't re-key a list to
  force a remount to fix a stale-child bug; find why the child is stale.

## Rendering Boundaries

<!-- Rendering-mechanism rows live in nextjs.md. What is general: -->

- **Server rendering is not "faster React" — it is a different component
  contract.** A component that runs on the server has no browser globals, no
  state, and no effects. If one of those is needed, it is a client component,
  and the boundary has to be declared.
- **Push the client boundary down, not up.** Every component above a client
  boundary is a client component too. A client boundary at the layout level
  makes the whole tree client-rendered.
- **A client boundary is a real cost**: its subtree ships JavaScript. Make it
  the smallest thing that needs interactivity.
- **Server and client components compose in one tree** — a server component may
  render a client component and pass it serialisable props. It may not pass a
  function, a class instance, or a non-serialisable value across the boundary.

## Composition

- **Compose from primitives; don't reinvent them** (`ui-components.md`
  §Primitives Over Custom).
- **One component per file**, unless two components are genuinely one thing
  (a component and its only-used-once sub-variant).
- **Props are a typed object with a `Props` suffix**, no inline anonymous type
  (`coding-standards.md` §Naming).
- **Children as `children`, not as a `component` prop**, unless the component
  needs to control placement or inject itself.
- **Conditional class merging goes through the project's utility**
  ({{e.g. `cn()`}}), never string concatenation — a later conflicting class
  silently wins depending on order.
- **A component library's styles are applied through its own mechanism**
  ({{e.g. the utility-class variant of a component, or the theme object}}),
  not through a parallel inline-style path.

## State

- **The full decision lives in `data-and-state.md` §Server State vs UI State.**
  The React-specific summary: server data belongs to the server-state library,
  and local `useState` holds only what the user is currently doing.
- **`useState` for a value, `useReducer` when the transitions are coupled or the
  next state depends on the previous one.** A reducer makes an invalid
  transition impossible; a `useState` setter makes it merely unlikely.
- **State is declared at the lowest common ancestor of its consumers.** Lifting
  it further re-renders everything in between.

## Hooks Rules

- **Hooks are called unconditionally at the top level.** No hook inside a
  condition, a loop, or a nested function.
- **Every `useEffect` has a cleanup when it subscribes, schedules, or
  subscribes to a store.** A subscription without teardown is a leak that shows
  up as a state update on an unmounted component.
- **The dependency array is not a hint.** A stale closure is a real bug, and the
  suppression comment that fixes it hides the next one too. If a dependency can't
  be listed, the effect is doing the wrong thing — restructure it.
- **A ref is not state.** Writing to a ref doesn't trigger a render; anything
  the UI must show belongs in state.
- **A custom hook that returns more than three things returns an object**, and
  its name says what it does, not that it's a hook.

## Named Footguns

- **Strict Mode double-invokes effects and reducers in development.** An effect
  that isn't idempotent — a subscription added twice, a request fired twice, a
  write performed twice — is a bug that will reach production on a different
  schedule. Write effects to be idempotent and to clean up completely.
- **A cleanup function's return value is ignored if the effect returns nothing
  else.** Returning a value that isn't a function or a destructor silently does
  nothing. A common source of "the cleanup never ran."
- **`key` on a conditional list branch resets the subtree.** Moving an element
  across a conditional boundary unmounts and remounts it, losing its state.
- **State updates are batched within an event handler** and are *not* batched
  the same way inside a promise callback or a timer in every version. Code that
  reads state immediately after setting it, in an async continuation, can read
  the previous value.
- **Rendering a component that both reads and writes the same store during
  render** produces an infinite loop that presents as a stack overflow with no
  useful frame.
