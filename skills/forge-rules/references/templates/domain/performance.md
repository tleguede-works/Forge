# Template · Performance

<!--
GENERATOR NOTES — delete this block in the emitted file.

This file exists to enforce one thing above all: measure before optimising.
Every audited project stated this rule independently, in its own words, and
every one of them also shipped rules that violate it — a memoisation sweep
applied "just in case", a list refactored without a measurement, an image
optimisation disabled to fix a one-off. The rules below are paired: each has a
counterpart forbidding the un-measured version of itself.

The performance *mechanisms* (which image component, which lazy-list primitive,
which memoisation hook) belong to the tech overlay. What is universal is the
threshold reasoning, the budget discipline, and the named footguns.

Do not emit a performance rule this project cannot measure. A rule whose
verification tool isn't in the project is a suggestion.
-->

# Performance Rules

> **Measure, don't guess.** No performance rule in this file is a licence to
> optimise. Each one describes what is cheap and what isn't, so the decision is
> cheap when it doesn't matter and measured when it does. A performance claim
> without a measurement is a guess, and a guess that goes the wrong way costs
> more than the problem it solved.

## Measuring

| To find out | Use |
|---|---|
| Where the time actually goes | {{the platform's profiler}} |
| What ships in the bundle | {{the build's size output}} |
| How often a component re-renders | {{the framework's render profiler}} |
| Frame rate / memory / startup | {{the platform's native tooling}} |

- **Reproduce before fixing.** A performance defect you can't reproduce is a
  performance defect you can't verify fixed.
- **Record what you measured** — the interaction, the frame, the number. "It
  felt slow" is not a measurement and does not survive a review.

## Lists

**The threshold, and it is a project decision not a law:** {{~20 items}}.

- **Below the threshold**, a plain map over a static collection is correct. Do
  not add lazy rendering, keys beyond the obvious, or row-extraction machinery
  to a list of eight.
- **At or above the threshold, or unbounded** — a list that grows with the data
  — use the platform's lazy/virtualized list. **Never render an unbounded
  collection with a plain map.** A connection can always grow.
- **Do not mass-refactor a working small list** into a lazy list without a
  measured slowdown. The refactor costs readability and buys nothing.
- **Stable keys, never the array index.** Index keys turn a reorder into a
  remount, and a remount loses local state and re-fires effects.

<!-- tech:web -->
- **Uniform rows can declare their height**, which lets the list skip layout.

<!-- tech:mobile -->
- **Rows are the platform's list primitive, not a `ScrollView` of children.**
  A screen that grows with its data must use the virtualized list; a
  `ScrollView` renders every child and the frame time grows with the data.
- **A long list on a low-end device is measured, not assumed.** Profile on a
  real device, not in a simulator or a browser's mobile emulation.
- **Memory is the real limit, not time.** A screen holding a few hundred
  decoded images at full resolution is the failure that a frame-time number does
  not show.

<!-- universal -->
- **No nested virtualized lists.** A list inside a list header defeats the
  outer list's windowing. Restructure into sections with sticky headers, or one
  flat list.
- **Keep rows cheap**: don't read a value that is constant for the screen once
  per row, and don't allocate per-row closures where a stable reference avoids
  it. {{Where the compiler already does this automatically, don't hand-add it
  and don't fight it — measure first.}}

## Images

**The biggest single lever in most applications, and the easiest to get
consistently wrong.**

- **Always specify dimensions** (or an aspect ratio and a fit mode) so the
  layout doesn't jump when the image arrives.
- **Request the size you actually render.** A thumbnail that downloads a
  full-resolution asset costs bandwidth, decode time, and memory, and it is the
  most common performance defect in image-heavy apps.
- **Use the platform's image component**, which handles resizing, caching, and
  progressive loading. A bare image element from the base framework usually does
  none of it.
- **Set a sensible cache policy and leave it alone.** Don't disable caching to
  fix a one-off — that trades a small stale-image risk for a permanent cost on
  every load.
- **A placeholder is not free.** A blurhash or skeleton that re-renders per row
  can cost more than it saves. Measure before adding one per item.
- {{e2e}}: **never disable image optimisation to work around a one-off sizing
  problem. Fix the sizing.**

## Fonts & Media

- **Load the application font once, at startup.** Don't dynamically load or
  reload it per screen.
- **Use the framework's font or asset pipeline** rather than a manually linked
  resource, so the asset is hashed, cached, and preloaded correctly.
- **Self-hosted fonts with explicit display and preload hints**, when the
  framework doesn't handle it.

## Re-render Cost

- **Keep the tree shallow.** Deep unconditional nesting of layout primitives
  costs work at every level. Extracting a subtree into its own component lets
  the framework skip it when its inputs haven't changed.
- **Narrow what a subscriber depends on.** Where the framework supports
  selecting a slice of state rather than the whole object, use it — a component
  that watches a whole object re-renders when any field changes.
- **Read state as close to the consumer as possible.** Passing a value down five
  levels means five components re-render when it changes.
- **Never set state during a render or build pass.** Derive during render; set
  state in an effect or an event handler.
- {{e2e}}: **don't read a context value per list item when it's constant for the
  screen.**

## Memoization

- **Memoize genuinely expensive computation** — a derived collection over a
  large array, a sort, a parse. **Not reflexively on every value.** Memoization
  has a real cost: memory, comparison, and complexity.
- **Every hand-added memoization should be justified by a measurement.** If the
  framework already memoizes automatically, adding it by hand is noise at best
  and a source of stale-value bugs at worst.
- **When hand-added memoization and a compiler disagree, trust the
  measurement.** The symptom of getting this wrong is a stale value that only
  reproduces sometimes.
- **A memoized value with the wrong dependencies is a correctness bug wearing a
  performance optimisation's clothes.** If you can't state the dependency list,
  remove the memoization.

## Code Splitting

<!-- universal -->
- **A heavy, rarely-used dependency is lazily loaded.** A charting library, a
  rich-text editor, a map, a date picker with locales — the cost is paid by every
  user on every route, to benefit the one who opens it.
- Don't split a module into so many chunks that the loading overhead exceeds the
  saving. Measure the actual effect on a production build.

<!-- tech:web -->
- **Route-level splitting is the default** for anything with more than one
  screen. {{Use the framework's routing-level lazy loading; don't preload
  screens the user hasn't navigated to.}}
- **A dynamic import is worth it above a size you measured**, not above one you
  assumed. Measure the chunk before adding the boundary.

<!-- tech:mobile -->
- **The binary is the first budget, not the last.** Everything linked is in
  every user's download. A heavy dependency is paid for on install, before the
  user sees a single frame.
- **Splitting is per-feature, not per-screen.** The bundle is resolved at build
  time; what you are actually deferring is initialisation, not download.
- **Route code is already split by the platform's route system.** Adding a
  manual dynamic import on top usually duplicates it.

## Budgets

<!-- tech:web -->
- **Pick a per-route payload budget** appropriate to this project
  and **check it when a route grows noticeably heavier**.
  {{e.g. a few hundred KB gzipped for a data-heavy route is a reasonable
  starting point; set the real number in `AGENTS.md`.}}

<!-- tech:mobile -->
- **Pick a startup-time budget and a binary-size budget.** Cold start to first
  frame, measured on a mid-range device — a simulator number is not a number.
- **The store listing has its own size limit**, and it is a release blocker,
  not a performance concern.

<!-- universal -->
- **A budget nobody checks is not a budget.** It goes in the Definition of Done
  or the review checklist, with the command that measures it.
- **When a page exceeds its budget, the fix is to find what's in it** — not to
  raise the number.

## Named Footguns

**These live in the technology overlays, not here.** A footgun is a concrete,
named, checkable fact about a *specific framework or platform* — it is true of
Flutter, or of a CSS layout, and meaningless in the abstract. Putting the list
here produced an empty section in every project that isn't that framework, which
is the "empty section is worse than no section" failure in its purest form.

`tech/<stack>.md` §Named Footguns carries the rows. The bar for a row, kept here
because the overlays follow it:

- **Someone could grep for it**, and it would save them an afternoon.
- **It states the symptom, not the cause** — the symptom is what you'll observe,
  and naming it is what makes the entry findable.
- **It says where to look first.** "If content overflows its container
  unexpectedly, this is one of the first things to check" is the difference
  between a useful entry and a curiosity.
- **It is a fact, not a fix.** The fix changes; the fact doesn't.

The reference entry, from the source material:

> A flex child without an explicit `min-w-0` can silently refuse to shrink below
> its content's natural width, breaking horizontal overflow and scroll on wide
> content inside it. If content overflows its container unexpectedly, **this is
> one of the first things to check**.

## When Blocked

- **If a screen feels slow: reproduce it, capture a trace, fix the measured
  cause.** Do not apply memoization across the app because "lists are slow" — a
  shotgun optimisation is hard to review, hides the real problem, and adds
  staleness risk everywhere it lands.
- **If a fix requires fetching a larger asset to work around a client-side
  limitation:** change the data layer to carry the right-sized asset
  (`data-and-state.md` §Images). Don't add a download-then-process step in the
  client.
- **If the fix is to disable a framework optimisation:** that is the wrong fix.
  Find the cause of the mis-sizing or the double-fetch.
- Never: optimise without measuring; add caching to hide a latency problem;
disable a correctness feature for a speed gain; raise a budget to make a
regression disappear.
