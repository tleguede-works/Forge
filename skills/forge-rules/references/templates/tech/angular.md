# Overlay · Angular

<!--
GENERATOR NOTES — delete this block in the emitted file.

Status: documentation-sourced, never applied end-to-end. Declare that status in
the emitted file (see the last section) — it is the same declaration
`java-spring.md` and `node-nestjs.md` carry, and leaving it off would let an
unvalidated overlay accumulate confidence it has not earned.

Emit alongside `typescript-javascript.md`, `core/quality-gates.md`, and
`domain/ui-components.md` / `domain/forms.md` / `domain/accessibility.md` where
their signals are present.

Provenance markers go on every technology claim, per
`documentation-sources.md`. Resolve the installed major from `package.json`
before writing any of it: Angular's defaults have changed across majors
(standalone by default, `strict` by default, and the builder change), and a rule
asserted from memory is the specific failure this skill exists to prevent.

Every version below marked *verify* must be re-checked against the installed
version's documentation before it ships. Do not emit an unverified one as a
rule — it becomes a question, a proposed ADR, or an unconfirmed finding.
-->

# Angular

## Commands

```bash
{{ng serve}}                 # dev server
{{ng build}}                 # production build — also runs the type-check and the budgets
{{ng test}}                  # unit tests — {{Karma or Vitest, whichever this project configures}}
{{ng lint}}                  # {{ng lint / eslint directly — confirm which this project uses}}
{{ng build --configuration=development}}
```

**Confirm the runner and the builder against `angular.json`, not against
memory.** Both changed recently and both are configured per-project.

## Standalone, and the NgModule question

**This project uses `{{standalone components | NgModules}}`.** State which, and
name the migration status if mid-way: a repository with both is normal during a
migration and is a defect afterwards.

- A **standalone** component declares its own `imports` and is bootstrapped with
  `bootstrapApplication`. No `declarations`, no `NgModule` to register it in.
- **Do not create an `NgModule` to group things** if this project is standalone
  — the grouping is the `imports` array, and a module reintroduces exactly the
  shared-mutable-state problem standalone components exist to remove.
- {{#if mid-migration}}**Extend the target shape; do not add to the deprecated
  one.** Adding a non-standalone component while the migration runs is a defect,
  even though using the existing ones isn't yet.
{{/if}}

## Change Detection

This is the one place where a performance bug looks like a style preference.

- **`OnPush` is the default for new components** in this project. `Default`
  change detection re-checks the component and its template on every tick of any
  event anywhere in the application; `OnPush` checks only when its own inputs,
  events or signals change.
- **A `BehaviorSubject` is not a signal.** Subscribing to one does not notify
  `OnPush` by itself — you need `markForCheck`, or an `async` pipe in the
  template. This is the most common cause of "the `OnPush` component does not
  update", and it is invisible until it ships.
- **Prefer signals for component state** where the installed version supports
  them; a signal read in a template participates in change detection natively.
- **Never call `ChangeDetectorRef.detectChanges()` to fix a stale view.** It is
  a diagnostic tool; shipping it is a symptom that was left in place.

## Components

- **A component is a class + template, and it owns its state and its inputs.**
  A component that fetches, transforms and renders three unrelated things is
  three components (`architecture.md` §File Size).
- **`@Input()` is an input, not a setter.** Do not transform an input in the
  setter and read it from the field: the input changes without the field
  changing, and the template reads the stale one. Compute in a getter.
- **Inputs are immutable.** An `Object.freeze`d model, or a development-mode
  deep-freeze in the store, turns "who mutated this" from a debugging session
  into a stack trace.
- **A component never calls the data layer directly** — through a service
  (`domain/data-and-state.md` §The Mandatory Access Shape).

## Dependency Injection

- **`inject()` over constructor injection** in this project, because it works in
  field initialisers and in any injection context. **State the preference; do
  not mix both in one class** — it reads as two conventions and behaves as one.
- **`providedIn: 'root'` for stateless services.** A service with state must
  be provided explicitly, and the question of *which* scope is a decision
  (`architecture.md` §Conventions).
- **An injection token over a string** whenever the injected thing is not a
  class. A string provider is a typo waiting to become a runtime failure.
- **Circular dependencies are a design defect, not a `forwardRef` problem.**
  `forwardRef` makes the cycle compile; it does not make it work, and at runtime
  one of the two is `undefined`.

## Templates

- **A template calls a component method only for cheap, synchronous reads.** A
  method call in a template re-runs on every change detection cycle; a pipe is
  pure, a method is not.
- **The `async` pipe, not `subscribe()` in the template-adjacent code.**
  Manual `subscribe` without `takeUntilDestroyed` leaks the subscription for the
  component's lifetime; the pipe unsubscribes itself.
- **No logic in the template beyond a single readable expression.** A ternary
  with nested ternaries in markup is `code-review.md` Pass 3 material.
- **`trackBy` / `@for` track on every list.** Without a stable identity, the
  reconciler recreates every node on every change.

## Routing and guards

- **A route is declared in `*routes` and nowhere else.** No path string is
  built at a call site (`architecture.md` §Conventions).
- **A guard returns `UrlTree` for a redirect, not `void` plus a side-effect
  navigation.** The `void` form navigates and then lets the guard's `true`
  activate the guarded route — a race, and a rare one.
- **Route-level `data` is the place for permissions metadata**, not a service
  lookup inside the component.

## Forms and Validation

- **Reactive forms, not template-driven ones**, in this project. Template-driven
  forms hide their own value: you cannot test them, and you cannot compose them.
- **One typed `FormGroup` per form, declared as a class property.** An untyped
  form with a `FormBuilder` chain is `any` with extra steps.
- **Validators return `ValidationErrors | null`** — never `false`, never a
  string. A validator returning a boolean produces an error key that no template
  can address.
- **Cross-field validation is a validator on the group**, not a subscription in
  the component.

## State

- **Server state and client state are separate** (`domain/data-and-state.md`).
  Angular's `HttpClient` is a transport, not a cache: if a value is fetched in
  two places, it is fetched twice, and the two copies drift.
- **A service holding state exposes signals, and the components read them.**
  A `BehaviorSubject` read through `.value` outside the subscription path reads
  whatever was last pushed, which is a race with the view.

## Budgets and Build

`angular.json` carries budgets, and **the build fails when one is exceeded.**

| Budget | Warn at | Error at | Note |
|---|---|---|---|
| `initial` bundle | `{{from angular.json}}` | `{{from angular.json}}` | Verify against the installed version — these defaults changed |
| `anyComponentStyle` | `{{from angular.json}}` | `{{from angular.json}}` | Per-component CSS, which is where component libraries leak |

- **A budget increase is a decision**, recorded in the decisions log with the
  reason. `ng build` failing on a budget is the mechanism working; raising it to
  make the build pass is the mechanism being defeated.
- **A component style over budget means the component owns too much CSS** — it
  is a `ui-components.md` §Primitive problem, not a budget problem.

## Generated Code

<!-- The one part of this overlay that is not opinion: Angular's schematics
     exist because hand-writing the boilerplate gets the selector, the module
     registration and the import wrong, and each of those fails at build time. -->

**Use `ng generate`. Do not create these files by hand.**

```bash
ng generate component <name>     # + the spec, the selector, the imports
ng generate service <name>
ng generate guard <name>
ng generate interceptor <name>
ng generate resolver <name>
ng generate pipe <name>
ng generate directive <name>
```

- A component created by hand and one created by the schematic differ in the
  selector format, the file naming style and the change-detection default, and
  **the defaults are per-workspace** — read `schematics` in
  `angular.json` for what this project actually produces.
- **The migration schematics exist and are ordered.** `ng generate
  @angular/core:standalone` converts to standalone, then removes empty
  NgModules, then switches the bootstrap. Run them in that order, and build
  between steps — the documented common failures (a file not covered by a
  tsconfig, code the analyser cannot follow) only surface if you stop between.
- **A file with a `// @ts-ignore` above it is often a schematic's limitation,
  not the code's.** Run the migration with `--verbose` before assuming the
  application has a real problem there.

## Testing

- **`TestBed` is the unit test harness.** Configure it once per suite; do not
  reconfigure per test — the configuration cost dominates the test.
- **A component test asserts on the rendered output and on emissions, not on
  internal fields.** `domain/testing.md` §Behaviour, Not Implementation applies
  unchanged.
- **A service is tested with an `HttpTestingController`, not by mocking the
  service under test.** Mock at the boundary (`domain/testing.md` §Mock at the
  Boundary).
- **The default runner matters**: {{Karma or Vitest}} — confirm from
  `angular.json`. The command differs, and a rule that names the wrong one
  produces a Definition of Done that cannot be satisfied.

## Named Footguns

| Symptom | Cause | Fix |
|---|---|---|
| `OnPush` component does not update | A `BehaviorSubject` mutated without `markForCheck` or the `async` pipe | Read it through the `async` pipe, or a signal |
| `ExpressionChangedAfterItHasBeenCheckedError` | State mutated during change detection — often a setter with a side effect | Compute in a getter |
| Subscription outlives the component | `subscribe()` in a field without teardown | The `async` pipe, or `takeUntilDestroyed()` |
| `ExpressionChanged` in dev only, fine in prod | Development mode re-runs detection a second time | Real lifecycle violation; do not suppress |
| Everything re-renders on every event | `Default` change detection | `OnPush`, then fix the fallout |
| Bundle budget exceeded after adding a library | The library ships all of its peers | Import the entry point, not the barrel |

## Banned Patterns

| Banned | Use instead | Enforced by |
|---|---|---|
| `skipLibCheck: false` without a reason | Keep it on — it hides real type breaks | `tsconfig.json` |
| `@ts-ignore` / `@ts-expect-error` on app code | Fix the type, or narrow explicitly | `coding-standards.md` §Type Safety |
| `subscribe()` without teardown | `async` pipe, `takeUntilDestroyed` | `rxjs-no-ignored-subscription` |
| A method call in a template doing work | A pipe, or a computed signal | `code-review.md` Pass 3 |
| `console.log` in source | `logger` service, at an intentional level | Lint rule / `workflow.md` §Code Hygiene |
| Hand-writing a component, service or guard | `ng generate <type>` | — (review) |
| `forwardRef` to break a cycle | Fix the dependency direction | — (review) |

## When Blocked

- A version-specific API is uncertain: **read the installed version's
  documentation**, never memory. This is the rule `documentation-sources.md`
  exists for, and Angular is exactly the case it was written about.
- A migration schematic fails on this codebase: **stop and report the exact
  error**, with the file and the reason. Do not hand-complete a migration the
  tool could not, without recording it as a manual step.
- The build fails only on a budget: **do not raise the budget to make it pass.**
  Fix the component (`ui-components.md` §Primitive), or record the decision.
- Never: `ng update` past a major without a dedicated branch · add a library
  and discover its peer dependencies through the budget error · suppress a
  budget check to land a change.

## Overlay Status

**Documentation-sourced, never applied end-to-end.** Every rule above was
written from Angular's documented behaviour for the pinned version, not from an
audited project. The mechanism is documented; the delivery path is unproven.

The first project to use this overlay finds out what was wrong, and the fix goes
here — which is what the next project copies. That declaration stays until an
overlay has actually been through a delivery.