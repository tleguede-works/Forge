# Template · Components & UI Structure

<!--
GENERATOR NOTES — delete this block in the emitted file.

Owns: where a component lives, how thin a screen stays, the design-token
discipline, the platform stance, and the motion vocabulary.

The design-token *mechanism* lives in `design-system.md` when that template is
emitted (it owns the project-specific contract). What stays here is the rule
that the tokens are used rather than bypassed, because that rule holds whether
or not the project has a formal design contract.

The performance consequences of component structure — code splitting, image
sizing, memoisation — are in `performance.md`. This file does not restate them.
-->

# Components & UI Structure

## Definition of Done

A component change is complete when **ALL** of:

1. No design literal in the component file — every value comes from a token
   (`design-system.md`, or the project's theme module).
2. Every interactive element has a role, a label, and a state
   (`accessibility.md`).
3. The component uses the project's UI primitives rather than a hand-rolled
   equivalent.
4. The screen it belongs to stayed thin — the logic is in the orchestration
   layer, not in the component.
5. {{e.g. every data-driven screen has loading, error, and empty states.}}

## Design Tokens

- **Every colour, font size, spacing step, radius, and duration comes from the
  token module.** No hex literal, no ad-hoc numeric style in a component file.
- **A one-off numeric style is a code smell. Promote it to a token after the
  second use** — the first use is legitimate; the second means it was never
  one-off.
- **Never redefine an existing token in a feature file.** If the value you need
  doesn't exist, **add it to the token module** using the module's own naming
  convention, then use it.
- **Use semantic tokens, not raw values.** A token that resolves per colour
  scheme is what makes dark mode work. A hardcoded dark-mode value inside a
  component breaks the moment a third scheme appears.
- **If a token's value is wrong for one screen, fix the token.** Do not
  override it locally with a near-miss value — that is how two near-identical
  values end up in the codebase.
- Where the project has a formal design contract (`design-system.md`), this
  section is governed by it and the two must agree.

## Primitives Over Custom

- **Use the platform or library's primitive whenever it covers the need.** Never
  build a custom control the library already provides — you inherit a worse
  version of accessibility, focus handling, and platform behaviour.
- **Fall back to a hand-rolled implementation only when the library genuinely
  has no equivalent**, and then say so in the code review of that change.
- **Primitives live in one shared folder** as thin wrappers, not scattered
  through features. A feature that needs a new primitive adds it there.
- **Never strip the semantics a primitive already carries.** Do not replace or
  override its accessibility and focus behaviour without a reason.

> **Verify the specific primitive's behaviour against the library's own
> documentation rather than assuming one library's pattern transfers to
> another.** Several libraries differ on real points — a select that renders
> the stored *value* instead of its *label*, a list component that is not
> virtualized, a group component that is not a list. A documented quirk is not
> a universal truth.

## Component Placement

| Component is used by | It lives in |
|---|---|
| One screen | in that screen's folder |
| More than one screen **within one** {{domain}} | `{{that domain's}} shared component folder` |
| More than one {{domain}} | `{{shared components folder}}` — and only then |
| A wrapper over a platform primitive | `{{shared UI primitives folder}}` |

**Don't jump straight to shared for something one {{domain}} uses three times.**
And promoting something to shared before it's actually shared is speculative
abstraction (`architecture.md` §Reusability Threshold).

## Thin Screens

A screen or page contains:

- layout and composition
- a themed header
- reads of state, and calls to the orchestration layer

**It does not contain:** validation logic, data transformation, business rules,
`{{try/catch}}` around a data call, direct data access, or a heavy computation.

When a screen stops being thin, extract its sections into
`{{features/<domain>/}}` components. When a section is reused, follow the
placement table above.

## Single Vocabulary

- **One styling system, one icon set, one date library, one formatting
  approach.** A second introduced ad hoc is a defect.
- **The shared loading/error/empty state components are used everywhere.** No
  per-screen hand-rolled three-way branch.
- **User-facing strings are keys, not phrases**, from the string module
  (`forms.md` §Messages, `i18n.md` when emitted). No inline string literals in
  markup.
- **Formatted values — money, dates, numbers — go through their one formatter.**
  Never assembled inline at the call site.

## Platform Stance

- **Pick a deliberate platform stance and keep it** — {{e.g. the platform's own
  conventions over a look-alike from another platform}}. Consistency within the
  app matters more than matching any one platform perfectly.
- **Don't fight the platform's native defaults** — native back behaviour, native
  sheet gestures, native keyboard handling. They are correct more often than a
  custom version.
- **When the UI genuinely must differ per platform, branch explicitly inside
  the component** — never maintain two whole screens that are 95% identical.
- **Respect the platform's safe areas and insets.** Never hardcode a top or
  bottom padding to clear a notch or a home indicator.
- {{e.g. a native-module feature cannot be verified in a runtime that doesn't
  include that module — testing it there and calling it verified is a false
  positive.}}

## Motion

- **Motion is small and purposeful.** It confirms an action, or it explains a
  spatial relationship. It is not decoration.
- **Reuse the established duration and curve vocabulary.** Don't invent a new
  value per animation — a set of one-off durations reads as jitter.
- **Respect the reduced-motion preference** for any custom animation, and for
  any transition that moves a lot of content.
- **No looping animation on content the user is trying to read**, and no
  animation whose only purpose is to look impressive in a demo.
- **Add a new motion pattern only with a justification** — a skeleton screen, a
  shared-element transition, a shimmer. Each one is a maintenance commitment,
  not a freebie.

## When Blocked

- **If a UI need has no primitive and no reasonable built-in: check the
  versioned documentation before inventing a custom implementation.** An
  official extension is usually better than a hand-rolled native view.
- **If a visual specification contradicts a token rule or an accessibility
  rule** — a contrast requirement, a touch-target minimum: **flag it in your
  reply rather than silently overriding the rule.** The design and the rule both
  need to change; that is a decision, not a local override.
- **If the design calls for a value the token module doesn't have:** add it to
  the module (`design-system.md` §Where New Values Go). Do not inline it "just
  for this screen".
- Never: hand-roll a control the library provides; add a second icon set;
  override a token locally; maintain per-platform duplicate screens; disable the
  reduced-motion check because a transition "needs" to run.

## Canonical Example

Once `{{the first screen built with the shared primitives and state
components}}` exists, treat `{{path/to/that/file}}` as the reference for
component composition in this project.
