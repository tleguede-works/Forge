# Variant · Material UI

<!--
GENERATOR NOTES — delete this block in the emitted file.

**This is a delta, not a replacement.** It states which files change relative to
`nextjs.md` and `react.md` when the project's component library is Material UI
rather than the project's default. It does not restate them.

Status: source-audited. Synthesised from the delta in the retired Next.js
profile; re-based onto the current overlay structure.

Note what does **not** appear here: a single accessibility rule. The accessibility
rules hold identically across component libraries — that was the finding from the
audited project, and it is the reason the rules live in a library-agnostic
template rather than in a variant.
-->

# Applying Material UI

Apply on top of `nextjs.md` when the project's component library is Material UI.
**An installed library settles this axis** — if the project already has one,
there is nothing to ask.

## Files that change

| In `nextjs.md` / `react.md` | Material UI instead |
|---|---|
| The default utility-class styling path | The library's own theming — a theme object, a provider, and the component's styling props. **Never a parallel inline-style or utility-class path alongside the library's**, or the two will disagree and neither is authoritative |
| `{{cn()}}`-style class merging | Not applicable. Styling is the theme plus the component's props |
| Primitives in a shared `{{components/ui}}` folder | Thin wrappers over the library's components, in the same shared folder. The wrapper's job is to bind the project's defaults — theme, spacing, variants — so features don't restate them |
| Icons imported individually from one set | The library's icon set, imported individually. **Still one set** — a second icon library is still a defect |

## Rules that change

- **The theme is the design system.** A variant is added to the library's theme
  once, in one place, and consumed by name from then on. A feature that
  overrides a variant's styling locally has forked the design system.
- **Component variants and props are the extension point, not a wrapper's
  inline styles.** If a project-specific appearance is needed twice, it is a
  theme variant.
- **Accessibility props are the library's own**, passed through
  (`accessibility.md`). The library's components carry the semantics; a wrapper
  must forward them rather than replacing them.
- **Colour and spacing come from the theme**, including the palette. A literal
  colour value in a component is a violation exactly as it is in the default
  variant.
- **The component library's own documentation is the authority on a specific
  component's behaviour** — which props it forwards, which accessibility
  semantics it sets, how its slots compose. Do not assume a pattern from a
  different library transfers prop-for-prop.

## Named difference worth knowing

**A select-like component in some design systems renders the selected item's
stored *value* in the trigger rather than its human-readable *label*.** Where
the value and the label differ — a numeric id, a status code, an enum — the
trigger displays the raw value, and the UI looks broken in a way that has no
obvious cause.

The fix is explicit: provide a render function that maps the value to its label.
**And the guard matters more than the fix: confirm that this project's actual
component behaves this way before applying the fix.** The behaviour is
library-specific and version-specific. Applying it reflexively to a component
that doesn't have it adds a mapping that isn't needed, and grepping the codebase
for components missing such a mapping becomes noise.

## Rules that survive unchanged

All of `accessibility.md` — identically. All of `ui-components.md`: the
primitive-over-custom rule, the placement taxonomy, thin screens, the single
vocabulary, the reduced-motion requirement. `design-system.md`, pointing at
whichever file *is* the project's contract. `performance.md`. `core/security.md`.

**If this project has a formal design contract** (`DESIGN.md` or equivalent) in
addition to the library theme, the contract is the intent and the library theme
is the implementation. A rule that treats the library's defaults as the design
system is wrong in a project that has a contract.
