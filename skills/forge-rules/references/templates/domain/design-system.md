# Template · Design System

<!--
GENERATOR NOTES — delete this block in the emitted file.

**This template never contains a colour, a font, or a spacing value.** It points
at the project's design contract and governs how that contract is used, extended,
and kept honest. A reusable template that shipped a palette would be a
liability: it would be pasted into every project and would be wrong in all of
them.

If the project has no design contract — no token module, no theme file, no
`DESIGN.md` — do not emit this file. Emit `ui-components.md` alone; its
token-discipline section is sufficient, and this file would be aspirational
rather than operational. Create a contract as a project decision first, then
emit this.
-->

# Design System Rules

## The Design Contract

**This project keeps its visual identity in `{{path}}`.** Read it before
introducing any new visual value.

{{Describe in one or two lines what the contract contains — the token set, the
type roles, the elevation model, the spacing scale — and where each part lives
if it is split across files.}}

- **Reference the contract, never restate it.** This file does not list the
  project's colours, and neither should any other rule file. A duplicated token
  list is a second source of truth, and it is the single most common way a
  design system stops matching the code.
- **When a rule elsewhere needs a token, it cites the contract by name.** If the
  contract and a rule disagree, the contract wins and the rule is the bug.

## Token Discipline

Full rules in `ui-components.md` §Design Tokens. The contract-specific
additions:

- **Named semantic tokens, not raw values.** The contract's tokens are named for
  their role ({{e.g. `surface`, `on-surface`, `danger`, `hairline`}}), not for
  their appearance. A token called `{{beige}}` cannot be re-themed, and its name
  will be a lie in dark mode.
- **A token resolves across every scheme the project supports.** Light and dark
  are two resolutions of the same semantic token, not two sets of tokens.
- **Never add a raw value to a component** to work around a token that doesn't
  cover the case. Add the token (`§Where New Values Go`).
- **Never redefine a token locally.** If a token's value is wrong for a screen,
  the token is wrong — fix it, and check what else used the old value.

## Where New Values Go

**The rule that keeps a contract from silently diverging from the code:**

1. The screen needs a value the contract doesn't define.
2. **Add it to the contract**, using the contract's own naming convention and
   its own structure — not as an extra entry appended at the end.
3. If the value is genuinely new *in kind* rather than a new instance of an
   existing role — a new spacing step, a new type role, a new elevation
   level — **that is a design decision, not a convenience.** Raise it before
   using it.
4. Then use the token. Never the literal.

- **One-off numeric styles are legitimate once.** The second use means it was
  never one-off — promote it then.
- **A magic number in a layout is a token that hasn't been created yet.**

## Approval

- **Who can add a token:** {{name or role, or "the project owner"}}.
- **A change to an existing token's value** — a colour, a type role, a spacing
  step — affects every screen that uses it. It goes through
  {{the project's normal review}}, because it is a visible change to the whole
  product, not a local edit.
- **A change to the contract that alters the product's visual identity** is a
  decision, and goes in the decisions log.
- {{If the project uses a design-token pipeline, add its generation/validation
  command here and make it part of the verification order.}}

## Component Variants

- **Variants live in the primitive, not in the feature that first needed one.**
  A "primary/secondary/danger" button that only exists as a conditional class
  in one feature is a variant that hasn't been promoted yet.
- **A feature that needs a genuinely new variant adds it to the shared
  primitive**, with the same states every other variant has — hover, focus,
  active, disabled, loading, and the accessibility wiring
  (`accessibility.md`). A variant with fewer states than its siblings is a
  defect.
- **A one-off composition is not a variant.** Compose existing primitives in the
  feature; don't fork a primitive for a single use.

## Contrast & Schemes

- **The contract's token values meet WCAG AA** — 4.5:1 body text, 3:1 large
  text and meaningful non-text — **in every scheme it defines.** A token that
  passes in one scheme and fails in another is a defect in the contract, and it
  is fixed there.
- **Verified on the rendered screen, not on the token value in isolation.**
  Opacity, blending, and disabled states change the effective ratio, and a
  disabled control is exactly where a designer is tempted to stop checking.
- **Fix the token, never the screen.** This file owns that rule; the ratios and
  the measurement method live in `accessibility.md` §Contrast, which is the only
  other place it appears. **Not** because a near-miss local override works — it
  works once, then two incompatible values exist in one codebase.

## Consistency

- **One spacing scale, one type scale, one radius set, one elevation model.**
  A value that isn't on the scale is a new decision.
- **Existing tokens are reused before new ones are created.** Adding a
  near-identical token is how a scale fragments.
- **The contract is the only place a design value is written down.** No
  screenshots, no one-off constants, no "temporary" values left in a component
  after a redesign.

## When Blocked

- **If a specified design can't be built from the contract's tokens:** that is
  the answer to "the contract is missing something" — raise it (`§Approval`).
  Do not approximate with a literal.
- **If a token's value conflicts with an accessibility requirement:** the
  accessibility requirement wins, and the token is corrected. Flag the conflict
  explicitly; don't quietly pick one.
- **If the contract and the existing code disagree:** the contract is the intent.
  Either the code drifts back, or the contract is deliberately revised — through
  `§Approval`, with the existing usages checked first.
- Never: inline a value to avoid touching the contract; fork a shared primitive
  for one feature; add a near-duplicate token; change a token's value without
  checking its other usages.

## Canonical Example

Once `{{the first screen built entirely from the contract's tokens}}` exists,
treat `{{path/to/that/file}}` as the reference for applying the contract in
practice.
