# Template · Architecture & Project Structure

<!--
GENERATOR NOTES — delete this block in the emitted file.

The file that answers "where does this go, and what is allowed to import what."
It owns four things, and nothing else owns any of them:

  1. The folder contract (the slots are here; the stack's actual paths are the
     tech overlay's).
  2. Dependency direction + the grep that enforces it.
  3. The centralized-concerns inventory — one canonical home per fact.
  4. The reusability threshold and the file-size rule.

This file is the canonical home for the file-size rule. No other rule file
restates it; they reference it. Do not put routing rules here (that is the
routing overlay), state rules here (that is data-and-state.md), or style here
(that is coding-standards.md).
-->

# Architecture & Project Structure

## Folder Layout

<!-- Emit the stack's real tree. The slots below are the required slots; a stack
     may add more but must be able to say where each slot lives. Annotate each
     entry with what belongs there AND what does not — the negative is the part
     that stops drift. -->

```
{{routes / entry points}}          {{e.g. every file is a screen}} — {{no logic, no data access}}
{{shared components}}             transversal only — nothing business-domain-specific
{{shared UI primitives}}          reusable wrappers over the platform/library primitives
{{features/<domain>/}}             one folder per business domain
{{shared hooks / controllers}}    orchestration used by more than one domain
{{lib / core}}                    utils, types, clients, schemas, formatters, mappers
{{config / constants}}            the single source of truth per concern — see below
{{tests}}                         {{co-located | mirrored | separate — pick one}}
```

## Dependency Direction

The rule, and its enforcement:

- **{{innermost layer}}** imports nothing from the framework, the network, the
  platform, or any UI package. It is pure logic and data shapes.
  - Verify: `{{grep}}` returns empty.
- **{{middle layer}}** may depend on the innermost layer. It must not depend on
  the outer layer.
- **{{outer layer}}** may depend on both. Nothing depends on the outer layer.
- **{{cross-cutting layer}}** depends on nothing inside `{{features}}`.
- **No cycles** between {{features}}. {{Verify: `{{tool that catches cycles}}`.}}

<!-- This is the single most consistent pattern across every audited project:
     every one has a layer rule AND a grep that proves it. A layer rule without
     an enforcing command is a suggestion — the agent cannot check it and will
     not hold it. Write the grep, run it once to confirm it works on the current
     codebase, and put it in the file. -->

- **Screens / pages / components never call the data layer directly** — only
  through `{{hooks / controllers}}`. If a component needs data no
  {{hook}} provides, **write the hook**; don't reach for a raw call inline.
  - Verify: `{{grep}}` returns empty.

## Centralized Concerns

Before creating a new formatter, util, constant, query key, validator, message
string, or component variant: **grep for an existing one first**
(`{{grep command}}`). Reuse it, extend it, or promote it.

**The right response to "this doesn't have it yet" is to add it to the canonical
module — not an inline literal at the call site, and not a second module.
Inline literals and parallel copies are violations even when the module doesn't
have the value yet.**

| Concern | Canonical home | Never |
|---|---|---|
| {{design tokens / colours / spacing}} | `{{path}}` | a literal in a component file |
| {{user-facing strings}} | `{{path}}` | a literal in JSX/markup |
| {{route/URL definitions}} | `{{path}}` | a string built at a call site |
| {{API/query keys or cache keys}} | `{{path}}` | a key invented per call site |
| {{API client instance}} | `{{path}}` | a second instance with different config |
| {{environment variables}} | `{{path}}` | read ad hoc at the call site |
| {{validation schemas}} | `{{path}}` | inline shape literals |
| {{date / currency / number formatting}} | `{{path}}` | `{{locale-format call}}` in a component |
| {{domain models / normalizers}} | `{{path}}` | a re-declared duplicate of a shape that exists |
| {{error type}} | `{{path}}` | a raw third-party error crossing into UI |

- Verify there is exactly one file per row: `{{grep that lists the canonical files}}`
  must return one path per concern.

## Reusability Threshold

**This is a different question from file size.** Not "is this file too big" but
"does this exact thing now exist in more than one place."

1. **First occurrence** — write it inline where it is used. Don't pre-emptively
   abstract.
2. **Second occurrence, near-identical** — note it, but two inline copies is
   still acceptable if the call sites are likely to diverge soon.
3. **Third occurrence, or a second you're confident won't diverge** — extract.
   - Used across more than one {{domain}} → `{{shared location}}`
   - Used only within one {{domain}} → keep it in `{{that domain's folder}}`.
     **Don't jump straight to shared for something one {{domain}} uses three
     times.**

**Promoting something to shared before it's actually shared is speculative
abstraction — the same anti-pattern as splitting a file before it's actually too
big.**

## File Size & Partitioning

**Line count is a signal, not a rule. Responsibility is the real metric.**

| Lines | Status | Action |
|---|---|---|
| 0–150 | Healthy | No action |
| 150–200 | Watch | Review for multiple responsibilities |
| 200–300 | Warning | Split logic into sub-modules, {{hooks}}, or utils |
| 300+ | Refactor | Must split — the file is doing too much |

**Split by responsibility, not by lines.** A 250-line file with ONE
responsibility is fine. Five small files with tangled concerns is not.

The deciding question: **"If I change X, should Y also need to change?"** If no
→ split.

**Signs a file needs splitting**

- Several unrelated state/effect groups in one file
- One unit rendering two distinct features
- A helper file with no cohesion
- {{e.g. a normalizer mixed in with screens}}
- Data access AND presentation in the same file

**Refactoring patterns**

- Extract sub-components into their own files
- Extract orchestration into a {{hook / controller}}
- Move constants and types into `{{constants}}` / `{{types}}`
- {{e.g. move form validation out of the component and the submission out of the
  validation layer}}

**Do not split artificially just to pass the threshold** — only split when it
improves coherence. Equally: **do not mass-refactor working code into a
"better" structure without a measured or concrete reason.**

## Conventions

- **`{{alias}}` for all internal imports.** Never relative imports across
  directories.
- **Import order:** external packages → `{{shared components}}` →
  `{{hooks}}` → `{{lib}}` → types.
- **Routes are defined in one place** — {{file-based routes, or a central
  routes module}} — and consumed from there. **Never build a path string by hand
  at a call site.** {{Dynamic paths are functions in the routes module, not
  string concatenation.}}
- **Navigation configuration lives with the route tree**, not scattered across
  screens.
- **Barrel exports (`index.ts`) are optional.** Don't add a re-export file just
  for the sake of it.
- **Screens stay thin**: layout, composition, and a themed header. The real
  logic lives in `{{hooks / controllers}}`. When a screen stops being thin,
  extract sections into `{{features/<domain>/}}` components.
- **Naming and file organisation** → `coding-standards.md`. Not here.
- **When adding a dependency** → `coding-standards.md` §Dependencies. Not here.

## When Blocked

- If the change requires a structure that contradicts this file: **stop and say
  so**, with the reason. A layout that needs an exception is a decision, not a
  convention.
- If two existing areas both legitimately need a concern: **flag the ambiguity**
  rather than picking one silently — the choice of canonical home is a decision.
- Never: add a second copy of a canonical concern to "get moving"; relax a
  layer rule to avoid a refactor; put shared code in a
  `{{features/<domain>/}}` folder because it was written there first.

## Canonical Example

Once `{{the first feature wired end-to-end}}` exists, treat
`{{path/to/that/file}}` as the reference for how this project structures this
kind of work — reference it, don't re-derive the pattern, and don't paste its
code into this file.
