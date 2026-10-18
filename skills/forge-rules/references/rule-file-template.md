# Rule File Template

The section skeleton, the ordering, and the section-tagging convention. Fill
sections in the order given — it is a priority order, not a style preference: an
agent needs to know how to build before it needs to know how to format.

**Note on where this file sits.** The domain and technology *content* lives in
`templates/`. This file defines the shape every emitted rule file takes, whether
it came from a template, was written from scratch, or was adapted during an
adoption. Use it when the template library doesn't have a template for a concern
the project needs.

## The tagging convention

**Every section carries a tag** saying when it applies. The generator keeps the
tagged sections that match the detected stack and deletes the rest.

```markdown
<!-- universal -->
## Applies in every project

<!-- tech:react-native-expo -->
## Applies to React Native / Expo

<!-- tech:web, tech:mobile -->
## Keyboard Operation
```

| Tag | Kept when |
|---|---|
| `universal` | Always |
| `tech:<stack>` | That overlay was selected by `stack-detection.md` |
| `tech:web` / `tech:mobile` | The project has that input model |
| `<condition>` | The stated condition holds for this project |

**Why this exists.** The same rule expressed for two platforms is one rule with
two expressions, and splitting it into two files produces two near-identical
files that drift. The clearest case is keyboard operation: tab order and focus
return on the web, field chaining and the focused field sitting under the
keyboard on mobile. One section, two tagged subsections, one rule.

**A section with no tag is treated as `universal`.** Tag anything that isn't.

### This is the mechanism that makes a stack reusable, not rebuilt

**Porting a pattern means taking a *section*, not inventing a file.**

The failure this prevents was measured: a React Native project was given a
Flutter-derived rule set, and the parts that were genuinely portable were
rewritten from scratch — losing the nuance that came from years of use — while
the parts that were genuinely Flutter-specific travelled along and had to be
corrected by hand.

| The situation | What to do |
|---|---|
| A section applies to this project too | **Keep it, retag it.** Change `tech:flutter-dart` → `tech:react-native-expo`, re-derive the examples, keep the rules |
| A section applies with one change | **Keep the section, change the platform branch** — the web/mobile tag above |
| A section names a Flutter-only mechanism | **Delete the section.** Do not port it "in spirit" |

**Re-derive the examples, not the rules.** A rule carries a concrete trigger; an
example carries a symbol from the source stack. `postmortems.md` Case 2's
addendum is exactly this: the contaminating word in a correctly-adapted rule is
almost always an example, not the rule around it.

**And say so in the emitted file's provenance line** — `<!-- adapted from:
domain/ui-components.md, tech:mobile branch -->` — so a later session knows a
rule arrived from somewhere and can check whether it still fits.

**A tagged section is still audited by the emitted set, not by the template.**
Tagging decides what survives; `audit-checklist.md` decides whether what
survived is right for *this* project. A rule carried across platforms and not
re-checked is contamination with a paper trail.

## The skeleton

Delete any section genuinely not applicable. **Never leave a section with
placeholder text or a vague heading** — an empty section is worse than no section,
because it reads as covered.

```markdown
# <Domain> Rules

## Commands
<Exact invocations relevant to this domain. Literal commands, not descriptions.>
- Install: `...`
- Lint: `...`
- Test: `...`
- Build: `...`

## Definition of Done
A change in this domain is complete when ALL of:
1. `<command>` exits 0
2. `<command>` exits 0
3. <any manual check specific to this domain>

## When Blocked
- If <specific failure> after 2 attempts: stop, report <exactly what to show>
- Never: <destructive shortcuts banned for this domain>

## When Writing <Domain>
- <task-scoped, checkable instruction>
- <task-scoped, checkable instruction>

## When Reviewing <Domain>
- <checkable review criterion, with the command that verifies it>

## Versions & Banned Patterns
- <Library/framework>: <exact version>
- Do NOT use:
  - `<banned API or pattern>` — <one-line reason>

## Canonical Example
- For <pattern X>, follow `<path/to/file.ext>` — do not paste the code here.

## Style
- <rule> — verified by `<lint command / rule ID>`
```

## The Generator Notes contract

Every template opens with a `GENERATOR NOTES` block, marked *delete this block in
the emitted file*. **This is the single most important convention in this
library, and it has a failure mode worth stating explicitly.**

The notes hold the reasoning: why a rule is shaped the way it is, which failure
mode it prevents, where the rule came from, and what happens if it is dropped.
**All of it is discarded on emit.** The emitted file gets the rule and nothing
else.

That is correct for *derivation* — an agent needs to obey the rule, not
reconstruct why it exists. It is wrong for *application* — a rule whose
reasoning has been thrown away cannot be extended to a case the template didn't
anticipate, and a rule set nobody can reason about is a rule set nobody
maintains. That decay is one of the failure modes this skill exists to prevent.

**So: the rule must carry its own why, in one clause, on the rule itself.**

| Belongs in the notes (deleted) | Belongs on the rule (kept) |
|---|---|
| Why this template consolidates what it consolidates | The one clause that changes how the rule is applied at a boundary |
| Which source project a rule came from | The concrete trigger condition |
| The defect that motivated a correction | Why the obvious alternative is wrong, when the agent would otherwise reach for it |
| How to fill the template | Nothing — that's instruction, not rule |
| What a previous version got wrong | Nothing — that's history |

**The test:** after the notes are deleted, could an agent apply this rule to a
case the template didn't anticipate? If not, the missing clause belongs on the
rule.

Concretely, in a template: a note reading *"Most agents place this here, which
puts it in the first paint; the audited project moved it because that was the
measured cost"* becomes a rule reading *"place it after the first paint —
placing it earlier was the measured cost in the audited project"*.

## What NOT to fill in

- **No prose explaining *why* a convention exists** in a paragraph. That belongs
  in human-facing docs — a README, an ADR. If the "why" matters to a judgement
  call the agent will need to make, compress it into one clause attached to the
  rule.
- **No adjectives without a check attached** — any word from `references/banned-wording.md`. No command, no
  concrete trigger, cut it or give it one.
- **No long code samples.** Reference a file. Pasted code goes stale silently; a
  file reference stays current.
- **No unranked list of things that could conflict.** If two items pull in
  different directions, label them.
- **No countable claim about a tool-generated file.** Cite a lint rule's *name*,
  never a count — counts drift on the next dependency bump and are false the
  moment they're written.
- **No reference to anything the reader can't reach** — not a template, not a
  profile, not a file that doesn't exist, not a symbol from another codebase
  (`postmortems.md` Case 2 and its addendum).

## What NOT to cut

Before removing anything in a rewrite or a merge, apply the "would the agent
violate this?" test from SKILL.md Principle 1. Don't re-derive the test here; it
lives in one place.

The one thing worth restating locally, because it's specific to drafting and
merging: **if you're merging this file's content into another, every rule that
passes the test must survive at comparable depth** — a full sentence or an
enforcing command, not a passing mention. A single bullet replacing a 100-line
file is a structural change wearing a success's clothing.

## What a template must never contain

Templates are copied into every project that selects them. Three categories are
therefore forbidden outright, regardless of how well-written they are:

| Forbidden | Why | Where it belongs instead |
|---|---|---|
| **Project-specific values** — a colour, a font, a token list, a domain name, a company | Wrong in every project that isn't that one, and confidently so | The project. `design-system.md` *references* the contract; it never restates it |
| **A count** — "44 lint rules", "13 files", "3 variants" | False the moment anything is added, and nobody re-checks it | Nothing. State the rule names |
| **A hedged rule** — "probably X, but verify" | Carries a rule's authority with a guess's reliability; the agent acts on it | A question, a proposed ADR, or an unconfirmed finding |

And one more, which is the failure mode of *this* library specifically: **a
template must not name another template or a source profile.** The rules must
stand alone in the project they land in.
