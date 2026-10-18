# Template · Accessibility

<!--
GENERATOR NOTES — delete this block in the emitted file.

Owns: role/label/state on interactive elements, the form-field wiring, keyboard
operation, focus management, contrast, reduced motion, and dynamic announcements.

This template is the clearest argument for section-tagging rather than one file
per technology. The web source and the mobile source each had a full keyboard
section — the web one about tab order and focus return, the mobile one about
field chaining and the focused field sitting under the keyboard. They are the
same rule ("every action must be operable without a pointer, and the focus must
stay visible") expressed for two input models. Splitting them into two files
would have produced two near-identical files; tagging the sections keeps one
rule with two platform expressions.
-->

# Accessibility Rules

## Definition of Done

A UI change is accessible when **ALL** of:

1. Every interactive element is reachable and operable by keyboard alone —
   including activation, dismissal, and focus return.
2. Every interactive element has a role, an accessible name, and — where it has
   a state — a programmatic state.
3. Every form field has an associated label, and its validation error is
   programmatically linked to it.
4. State is never conveyed by colour alone.
5. {{e.g. contrast meets the minimum in every scheme the project supports.}}
6. {{e.g. touch targets meet the platform minimum.}}

## Role, Label, State

- **Every interactive element declares a role and an accessible name.** A
  visible text label counts as the name; otherwise set it explicitly. An
  unlabelled icon button is invisible to a screen reader.
- **Prefer the platform's semantic element** over a generic container with a
  click handler. Use ARIA roles to fill a genuine gap, not to add semantics that
  the native element already provides.
- **State is programmatic, not visual.** A disabled, selected, checked, or
  expanded state is exposed as state — and **never signalled by colour alone**.
  Pair colour with an icon, text, or a shape change.
- **Group related items into one accessible element** where a screen reader
  would otherwise read a list of fragments piece by piece.

## Form Fields

- **Every input has a label**, associated programmatically. An `aria-label` is
  the fallback when a visible label isn't possible — it is not the first choice,
  because a visible label helps more people.
- **Every validated field carries its invalid state and its error text**,
  programmatically linked to the field. The error must be announced when it
  appears, not only be present in the DOM.
- **Placeholder text is not a label.** It disappears on input and is frequently
  too low-contrast to read.
- **A required field says so programmatically**, not only with an asterisk.

## Keyboard Operation

**Every action must be possible without a pointer.** This is the rule; the
expressions below are per input model.

<!-- tech:web -->
- Every interactive element is reachable in a logical tab order, and activates
  with the platform's activation keys.
- **Focus is always visible.** Never remove the focus indicator without replacing
  it with something at least as visible.
- **A custom interactive element handles keyboard events explicitly** — a
  `{{div}}` with a click handler is not a button.
- **Overlays trap focus while open and return it to the trigger on close.**
  Closing a dialog and dropping focus to the document body disorients keyboard
  and screen-reader users more than the dialog helped.

<!-- tech:mobile -->
- **Form fields chain in visual order.** The return key advances to the next
  field; the last field submits.
- **The focused field is never left under the keyboard.** The form container
  handles avoidance explicitly, and — on platforms where the container alone
  does not reveal the focused field — each field scrolls itself into view.
- **The keyboard does not block the submit control.** A tap on a button while
  the keyboard is open must work; this is an explicit configuration, not a
  default to rely on.
- **A hardware or platform back action works from any screen**, and is guarded
  where the platform's behaviour makes it unreliable.

## Dynamic Updates

- **A change that happens without a page load is announced.** A count that
  updates, an item added to a basket, a validation error that appears, a save
  that completes.
- Routine updates use a polite live region; **errors and destructive results
  use an assertive one.** Assertive interrupts whatever the user is doing, so it
  is reserved for things they must know immediately.
- **A silent mutation is a bug**, not a preference. If the screen changed, a
  screen-reader user needs to know.

## Contrast

- **Text meets the WCAG AA minimum** — 4.5:1 for normal text, 3:1 for large
  text. {{Adjust if the project has a documented higher target.}}
- **Checked in every scheme the project supports**, not just the default one. A
  token that passes in light mode and fails in dark mode is a defect.
- **Non-text UI — focus indicators, control borders, icons carrying meaning —
  meets 3:1** against their background.
- **If contrast fails, fix the token, not the screen.** The rule and the
  rationale are owned by `design-system.md` §Contrast; the ratios and the
  measurement method are owned by this section. One owner per fact.
  A local override with a near-miss value is how two incompatible values end up
  in the same codebase.

## Touch Targets

- **Interactive targets meet the platform minimum** — {{e.g. 44×44 pt on
  mobile, 24×24 CSS px on the web}}. Where a visual element is smaller, its
  hit area is expanded to meet the minimum.
- **Adjacent targets are separated** so a mis-tap doesn't hit the wrong one.
- Dense rows that can't meet the minimum use a different interaction — a menu
  affordance, a swipe, a selection mode — rather than sub-minimum targets.

## Images

- **An image that carries information has a description.** An image that is
  purely decorative is marked as such and hidden from assistive technology — a
  missing alt attribute is not the same as an empty one.
- **Don't put meaning in an image's alt text that isn't there visually.**
- {{e.g. an icon-only control's accessible name comes from its label, not from
  a filename or a hash.}}

## Native Semantics

- **The platform and library primitives already carry semantics. Don't strip
  them.** Overriding a primitive's accessibility behaviour needs a reason.
- **Verify a specific primitive's accessibility behaviour against the library's
  own documentation.** Behaviour differs between libraries, and a pattern that
  worked in one is not evidence about another.
- {{e.g. when wrapping a native control, forward the accessibility props rather
  than hardcoding new ones.}}

## Reduced Motion

- **Any custom animation respects the reduced-motion preference.** Checked at
  runtime where the platform exposes it, and declaratively where it exposes CSS.
- **Reduced motion means reduced, not removed in a broken way** — the state
  change still has to be perceivable. Swap the animation for an instant change,
  don't skip the feedback.

## Verification

- **Run the platform's semantics inspector** on the flows that matter — a form
  submit, a dialog, a dynamic list. It is faster than reasoning about the
  accessibility tree.
- **Navigate the flow with a keyboard only, once, before calling it done.** Most
  accessibility defects are found this way in under a minute.
- **Check contrast on the actual rendered screen**, not on the token values in
  isolation — opacity and blending change the effective ratio.

## When Blocked

- **If an accessible implementation is blocked by a primitive's own behaviour:**
  work around it in the wrapper, don't disable the semantics.
- **If a required contrast ratio cannot be met with the current palette:** that's
  a design decision — raise it, don't ship the unreadable version and note it
  later.
- Never: remove a focus indicator; use colour as the only signal; replace a
  semantic element with a generic one to make styling easier; add an ARIA role
  that contradicts the native semantics; mark a meaningful image as decorative
  to silence a warning.

## Canonical Example

Once `{{the first fully accessible form or dialog}}` is built, treat
`{{path/to/that/file}}` as the reference for label, error, and focus wiring.
