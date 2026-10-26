# v3 templates: what they force, what they leave to guesswork

## Scope and method

Audited: the 23 files named in the brief — 17 `*-template.md`, plus `slices-format.md`,
`formats.md`, `hierarchy.md`, `review-checklist.md`, and the `forge-rules` references
`target-formats.md` and `workflow.md`. Every claim below is either a `path:line` in v3, a `path:line`
in the v2 clone at `C:\Users\Thibaut LEGUEDE\AppData\Local\Temp\opencode\v2-baseline`,
or the output of a command printed here or in the finding.

Registered template names: read from `HEADINGS` (`cli/forge.py:92-115`) — 12 names.
`cmd_template` (`cli/forge.py:151-156`) refuses any other name (`cli/forge.py:152-153`).
`forge template <name>` was run for all 12 names, plus the 8 names that look like
deliverables and are not registered (`layouts`, `screen`, `screen-map`, `slices`,
`plans-index`, `plan`, `screen:SCR-1`, `plan:S1`). Output pasted below.

Ground truth for "what the CLI parses":

| Mechanism | Function | Line | File read |
|---|---|---|---|
| Section presence + non-empty | `structure_problems` | `cli/forge.py:135-148` | any deliverable with a `HEADINGS` entry |
| Heading/anchor match | `_heading_matches` | `cli/forge.py:122-124` | same |
| PRD ID universe, out-of-scope split | `parse_prd` | `cli/forge.py:727-735` | `prd.md` |
| Duplicate/reused/absent IDs | `prd_problems` | `cli/forge.py:738-751` | `prd.md` |
| `L<n>` ↔ `OB-<n>` both ways | `compliance_prd_problems` | `cli/forge.py:1374-1391` | `prd.md` + register |
| Register header + `OB` columns | `parse_register`, `compliance_problems` | `cli/forge.py:1313-1371` | `compliance-register.md` |
| Roadmap covers every ID | `roadmap_problems` | `cli/forge.py:754-763` | `prd.md` + `roadmap.md` |
| Slice rows | `parse_slices` | `cli/forge.py:766-775` | `slices.md` |
| Every ID served by a slice | `coverage_problems` | `cli/forge.py:778-795` | `slices.md` |
| Plan headings, 1–15 tasks, `serves` equality, `TC-` lines | `plans_problems` | `cli/forge.py:813-845` | `plans/*.md`, `plans/index.md`, `test-plan.md` |
| Screen map, layouts, anatomy, H1/H2 | `design_problems` | `cli/forge.py:629-701` | `design/screen-map.md`, `design/layouts.md`, `design/screens/*.md` |
| Layout region ⇒ plan task | `layout_plan_problems` | `cli/forge.py:704-712` | `design/layouts.md` + `plans/*.md` |
| Rule set: 10 checks | `rules_checks` | `cli/forge.py:1040-1182` | rule files + entry file |
| `- target:` / `- budget:` | `rules_cfg` | `cli/forge.py:1197-1202` | `rules-report.md` |
| Print a structure | `cmd_template` | `cli/forge.py:151-156` | `HEADINGS` only |

Classification used in the inventory and the findings:

- **checked** — the CLI parses the section's content and refuses a missing, empty or
  malformed body (`structure_problems` plus a per-phase function).
- **unchecked** — the CLI only requires a non-empty body; the template hands the writer
  an explicit shape (table with named columns, field list, one-per-line rule), so a weak
  model can fill it and a reviewer can see a gap.
- **vacuous** — the CLI only requires a non-empty body and the template body is empty or
  a bare instruction: a single character satisfies it, so a filled deliverable and an
  empty one are the same object to every mechanical check.

Nothing was written inside the repository except this file. No `forge init` was run. To
test the parsers instead of guessing, a throwaway tree was fabricated at
`C:\Users\Thibaut LEGUEDE\AppData\Local\Temp\opencode\forge-audit-02\.forge\` (no
`state.json`, no Forge project) and the parser functions were called on it directly; the
commands and their output are quoted in F2, F3, F7 and F8.

`forge template` output, verbatim (brief):

```
# brief

## 1. Request in the client {#request-in-the-client}
<fill>

## 2. Goal and success measure {#goal-and-success-measure}
<fill>

## 3. Users {#users}
<fill>

## 4. Target countries and regulated areas {#target-countries-and-regulated-areas}
<fill>

## 5. Payments, subscriptions and data {#payments-subscriptions-and-data}
<fill>

## 6. Stated technical constraints {#stated-technical-constraints}
<fill>

## 7. Deadline and budget signals {#deadline-and-budget-signals}
<fill>

## 8. Who answers {#who-answers}
<fill>

## 9. Open questions {#open-questions}
<fill>
```

The other 11 differ only in their headings, each followed by the same bare `<fill>`:
`contract` 6 sections (`parties-and-roles`, `how-the-work-runs`,
`touchpoints-and-answer-times`, `changes-after-approval`, `not-included`,
`language-of-deliverables`); `landscape` 6 (`idea-and-premise-challenge`,
`archetype-and-core-loop`, `products-studied`, `invariants`, `decisions`,
`research-outcome`); `compliance-register` 4 (`scope`, `obligations`,
`open-legal-questions`, `limits-of-this-register`); `prd` 10 (`problem-and-audience`,
`goals-and-success-measures`, `business-rules`, `edge-cases`, `validations`,
`constraints`, `legal-requirements`, `user-stories`, `open-questions`, `out-of-scope`);
`roadmap` 5 (`mvp`, `r1`, `r2`, `trade-offs`, `coverage`); `design-references` 5
(`archetype-and-core-loop`, `reference-products`, `mood`, `anti-references`,
`directions-presented-to-the-client`); `design-system` 6 (`colors`, `typography`,
`spacing-and-radius`, `primitive-components`, `navigation`, `motion-and-feedback`);
`architecture` 10 (`stack-and-justification`, `modules`, `foundations`, `slices`,
`data-model`, `api-contracts`, `external-integrations`, `dependencies`,
`deployment-and-configuration`, `risks-and-open-questions`); `rules-report` 4
(`files-produced`, `template-selection`, `baseline-status-of-each-gate`, `audit-output`);
`test-plan` 4 (`strategy`, `coverage-matrix`, `regression-set`, `environments-and-data`);
`validation-report` 4 (`test-plan-results`, `deviations-from-the-plans-and-the-prd`,
`requirements-not-met`, `acceptance-summary`). `python cli/forge.py template prd` prints
32 lines, 0 table rows, `<fill>` on every section (`has <fill>: True`, `tables: 0`).

The 8 unregistered names are refused, in one run:

```
=== layouts
forge: no structure is defined for 'layouts' (known: architecture, brief, compliance-register, contract, design-references, design-system, landscape, prd, roadmap, rules-report, test-plan, validation-report)
=== screen          same refusal
=== screen-map      same refusal
=== slices          same refusal
=== plans-index     same refusal
=== plan            same refusal
=== screen:SCR-1    same refusal
=== plan:S1         same refusal
```

## Template inventory

`lines` is `len(text.splitlines())` per file (command in F1's evidence style). `sections`
counts the sections the template itself defines, not the `HEADINGS` count, when the two
differ (screen, layouts, slices, plans-index, plan). `checked + unchecked + vacuous =
sections`.

| Template | Lines | Sections | Checked | Unchecked | Vacuous | Verdict |
|---|---|---|---|---|---|---|
| `forge-bootstrap/references/brief-template.md` | 15 | 9 | 0 | 4 | 5 | too vague |
| `forge-bootstrap/references/contract-template.md` | 12 | 6 | 0 | 3 | 3 | partly broken |
| `forge-discover/references/landscape-template.md` | 23 | 6 | 0 | 6 | 0 | adequate |
| `forge-discover/references/prd-template.md` | 18 | 10 | 6 | 0 | 4 | too vague (critical) |
| `forge-discover/references/roadmap-template.md` | 15 | 5 | 1 | 2 | 2 | too vague |
| `forge-compliance/references/register-template.md` | 21 | 4 | 1 | 3 | 0 | adequate |
| `forge-design/references/design-references-template.md` | 12 | 5 | 0 | 4 | 1 | too vague |
| `forge-design/references/design-system-template.md` | 13 | 6 | 0 | 4 | 2 | too vague |
| `forge-design/references/screen-template.md` | 22 | 6 | 1 | 4 | 1 | partly broken |
| `forge-design/references/layouts-template.md` | 7 | 1 | 1 | 0 | 0 | adequate (thin) |
| `forge-architect/references/architecture-template.md` | 25 | 10 | 0 | 6 | 4 | too vague |
| `forge-architect/references/slices-format.md` | 12 | 1 | 1 | 0 | 0 | adequate |
| `forge-rules/references/rules-report-template.md` | 18 | 4 | 0 | 4 | 0 | adequate with caveat |
| `forge-rules/references/rule-file-template.md` | 199 | 18 | 18 | 0 | 0 | adequate (generator) |
| `forge-rules/references/target-formats.md` | 246 | 11 | 11 | 0 | 0 | adequate (reference) |
| `forge-rules/references/workflow.md` | 249 | 9 | 0 | 9 | 0 | adequate (reference) |
| `forge-plan/references/plan-template.md` | 17 | 5 | 3 | 2 | 0 | adequate |
| `forge-plan/references/plans-index-template.md` | 5 | 1 | 1 | 0 | 0 | adequate (minimal) |
| `forge-plan/references/test-plan-template.md` | 14 | 4 | 1 | 2 | 1 | partly broken |
| `forge-build/references/validation-report-template.md` | 14 | 4 | 0 | 4 | 0 | too vague |
| `forge-design/references/formats.md` | 33 | 6 | 6 | 0 | 0 | adequate (spec) |
| `forge-design/references/hierarchy.md` | 27 | 2 | 2 | 0 | 0 | adequate (spec) |
| `forge-design/references/review-checklist.md` | 12 | 0 | 0 | 0 | 0 | adequate (spec) |

Totals for the 16 deliverable templates: 86 sections, **15 checked (17 %), 48 unchecked
prose, 23 vacuous**. `rule-file-template.md`, `target-formats.md`, `workflow.md`,
`formats.md` and `hierarchy.md` are counted as checked where `rules_checks`
(`cli/forge.py:1040-1182`) or a `parse_*` function enforces them; they are specifications
and generators, not forms a model fills.

## Findings

### F1 — `forge template` prints a skeleton the CLI then refuses

- **Ref** `cli/forge.py:151-156`, `cli/forge.py:333`
- **Status** verified
- **Severity** critical
- **What** The documented starting point for a deliverable is a list of headings each
  followed by `<fill>`, and `<fill>` is an explicit registration error. The two things
  called "the template" — `HEADINGS` in code and `references/*-template.md` on disk —
  are never compared except by heading name.
- **Evidence** `cmd_template` prints `f"## {i}. {title} {{#{slug}}}\n<fill>\n"`
  (`cli/forge.py:156`). `cmd_register` refuses on
  `re.search(r"\{\{[A-Z_]+\}\}|\bTODO\b|\bTBD\b|<fill>", txt)` (`cli/forge.py:333`).
  `python cli/forge.py template prd | python -c "import sys,re;t=sys.stdin.read();print('has <fill>:',bool(re.search(r'<fill>',t)),'tables:',t.count('|'))"`
  → `has <fill>: True tables: 0`. `skills/forge/SKILL.md:23` sends the model to
  `forge template <name>` for the anchors; `docs/STATUS.md:9` calls it "the skeleton".
  `tests/templates.sh:15-20` compares only that each `HEADINGS` key appears in the
  template's headings; it never checks column headers, field counts or that the printed
  skeleton is registrable.
- **Impact** A model that follows the documented path produces a file the gate refuses,
  and the refusal message (`cli/forge.py:337`) points back at the command that produced
  it. A model that instead copies `references/*-template.md` gets tables the CLI never
  printed, so the two sources can drift in the direction of silence. Every test fixture
  in the kit is built from the stub (`tests/e2e.sh:7`, `tests/audit.sh:6`,
  `tests/compliance.sh:11`, `tests/adversarial.sh:7`, `tests/rulesphase.sh:6`,
  `tests/loops.sh:11`, `tests/install.sh:32` — `forge template "$1" | sed
  's/<fill>/sample text/'`), so no suite ever registers a file shaped like the reference
  template.
- **Recommendation** One source: make `cmd_template` print the content of the mapped
  `references/*-template.md` (add the mapping as a `TEMPLATE_FILE` dict beside `HEADINGS`)
  and keep `HEADINGS` derived from it. Add a suite case that pipes
  `forge template <name>`, replaces a documented `<fill>` marker, registers, and expects
  either success or a named refusal — under I4 this hole has no test today.

### F2 — Every template's `<placeholder>` passes the placeholder ban, so a verbatim template copy passes the PRD phase

- **Ref** `cli/forge.py:333`, `skills/forge-discover/references/prd-template.md:6-14`
- **Status** verified
- **Severity** critical
- **What** The ban matches `{{TOKEN}}`, `TODO`, `TBD` and `<fill>`. It does not match the
  `<rule>`, `<case and expected behavior>`, `<constraint>` form that the templates
  actually use. A PRD that is the template with four one-character bodies passes
  structure, PRD IDs, coverage, roadmap and the `L`↔`OB` check.
- **Evidence** Harness run, output verbatim:
  `register placeholder ban hits on template text: []`;
  `angle placeholders kept in file: ['<case and expected behavior>', '<constraint>',
  '<input rule and error behavior>', '<product name>', '<removed requirement>', '<rule>']`;
  `structure_problems: []`; `prd_problems: []`; `coverage_problems: []`;
  `roadmap_problems: []`; `compliance_prd_problems: []`. The file was 514 bytes and 31
  lines and read `## 3. Business rules` / `- B1 <rule> (source: landscape row / user-stated)`.
  `docs/AUDIT-2026-10-19.md:51` records the intent: "refuses empty sections and `<fill>`
  markers".
- **Impact** The escape hatch sits exactly where a weak model starts. Everything the
  registration check was built to prevent (an unfilled form reaching a reviewer as if it
  were content) survives in the form the templates teach. The same holds for
  `register-template.md:3-5` (`<country or region codes, comma separated>`), which is only
  caught by accident because `compliance_problems` validates the `source` URL
  (`cli/forge.py:1352`).
- **Recommendation** Extend the ban to `<[^>]{2,60}>` outside fenced code blocks, and add
  a `tests/` case that registers each reference template verbatim and expects the refusal
  naming the placeholder. This is a one-line regex change plus 12 fixtures, and it is the
  cheapest quality gate in the kit.

### F3 — Six required structures have no `HEADINGS` entry: the CLI refuses to print them and checks nothing at registration

- **Ref** `cli/forge.py:139`, `cli/forge.py:325`, `REQUIRED` at `cli/forge.py:10-22`
- **Status** verified
- **Severity** critical
- **What** `screen-map`, `layouts`, `slices`, `plans-index`, `plan:<Sxx>` and `screen:<id>`
  are registered deliverables with usable names and no section list. `structure_problems`
  iterates `HEADINGS.get(name, [])` (`cli/forge.py:139`), so it returns `[]` for all six
  and `cmd_register` (`cli/forge.py:335-337`) accepts any text at all.
- **Evidence** The 8 refusals quoted in Scope and method. Harness run:
  `structure_problems layouts : []` on the input `"garbage with no headings at all"`;
  the same `[]` for `screen-map`, `slices`, `plans-index` and `screen:SCR-001`. For
  `plans-index`, the only check is a mention of each slice id:
  `re.search(rf"\b{sid}\b", itxt)` (`cli/forge.py:837`) — a file containing `S01` anywhere
  passes.
- **Impact** Three of the six are rescued by a `parse_*` function that reads a format the
  template file describes (`formats.md:3-18`, `slices-format.md:3-10`), so their content
  is enforced but their structure is not: a `layouts.md` with one region passes
  `layout_plan_problems` while its required "responsive behavior per region"
  (`layouts-template.md:7`) is unread. `plans-index` and `screen` are not rescued: a screen
  file with only `## Purpose` and `## Anatomy` passes both registration and
  `forge design check` (F7). A model cannot discover the expected structure from the CLI
  at all — the only source is the skill text, which points at a reference file.
- **Recommendation** Add `HEADINGS` entries for `screen-map`, `layouts`, `slices`,
  `plans-index`, `plan`, and a `screen` skeleton keyed by the `screen:` prefix
  (`phase_of`/`PREFIX_PHASE` at `cli/forge.py:23` already models multi-instance names).
  Add their template files to `tests/templates.sh`'s `MAP` (`tests/templates.sh:8-13`).

### F4 — `design-system.md` is required, 13 lines long, and read by nothing

- **Ref** `cli/forge.py:16`, `cli/forge.py:106-107`, `skills/forge-design/references/design-system-template.md:1-13`
- **Status** verified
- **Severity** major
- **What** The design system is the document a weak model most needs to be concrete in
  (token values, states, scale). In v3 it is a list of six headings, two of them empty,
  and no function ever opens the file.
- **Evidence** `grep design-system cli/forge.py` returns exactly two hits: `REQUIRED`
  (`cli/forge.py:16`) and `HEADINGS` (`cli/forge.py:106`). `design_problems`
  (`cli/forge.py:629-701`) reads `screen-map.md`, `layouts.md` and `screens/*.md` only.
  Empty sections in the template: `## 3. Spacing and radius`
  (`design-system-template.md:8`), `## 6. Motion and feedback` (`:13`) — 2 of 6, confirmed
  by the `structure_problems` count. `docs/IMPROVEMENTS.md:299` already records "The v2
  design-system contrast check was not ported". v2's template was 262 lines with a token
  section per family and a gate checklist
  (`v2-baseline/skills/forge/templates/design-system.md.tmpl:78-176,308-341`).
- **Impact** A deliverable whose whole purpose is to kill "to be defined later" is the one
  the CLI cannot see. `forge design check` passes with `## 1. Colors` holding `x`, and the
  screen files cite tokens nothing resolves — v2 measured that
  (`v2-baseline/skills/forge/SKILL.md:638-684`), v3 neither measures nor parses.
- **Recommendation** Parse the colors table (`| Token | Value | Use | Contrast on its
  background |`), refuse a `Value` that is not a hex/`rgb()`/`var(--…)` and a `Contrast`
  cell with no digit-to-digit ratio; then refuse a token cited in `screens/*.md` that the
  table does not define — the same cross-file shape as
  `layout_plan_problems` (`cli/forge.py:704-712`). Cite the refusal from `forge gate check`
  in `design`.

### F5 — `architecture.md`: 10 sections, 4 empty, 0 parsed; coverage is proved through `slices.md`

- **Ref** `cli/forge.py:108-110`, `skills/forge-architect/references/architecture-template.md:7,20,24,25`
- **Status** verified
- **Severity** major
- **What** `architecture` is a registered deliverable whose sections are only checked for
  presence. The gate's coverage check reads `slices.md` and never the architecture
  document, so "Data model", "API contracts", "External integrations" and "Deployment and
  configuration" can each hold one character.
- **Evidence** `grep architecture cli/forge.py` → only `REQUIRED` (`cli/forge.py:17`) and
  `HEADINGS` (`cli/forge.py:108-110`); `coverage_problems` (`cli/forge.py:778-795`) reads
  `prd.md` + `slices.md`. Empty in the template: `## 2. Modules` (`:7`), `## 7. External
  integrations` (`:20`), `## 9. Deployment and configuration` (`:24`),
  `## 10. Risks and open questions` (`:25`) — 4 of 10. v2's
  `architecture.md.tmpl` was 193 lines with a per-entity block (`:87-100`), an
  API-contract block per endpoint (`:129-169`), a dependency graph (`:171-212`), ADRs
  (`:214`) and a 10-item gate list (`:262-273`); `v2-baseline/skills/forge/SKILL.md:755`
  states the rule "tous les modèles sont définis champ par champ, pas résumés".
- **Impact** The phase most exposed to a weak model's hand-waving — field-by-field models,
  error codes per endpoint — has no shape and no check. `forge check coverage` passes on a
  slice table while every contract is prose. The v2 rule was a gate item; v3 keeps the
  sentence in the skill (`skills/forge-architect/SKILL.md:33`, A4) with no artifact that
  can satisfy or fail it.
- **Recommendation** Parse two tables in `architecture.md` — one per entity
  (`entity | field | type | null | constraint | index`) and one per endpoint
  (`method | path | input | output | errors | auth | serves`) — and refuse an entity used
  by no slice or a `serves` ID that is not live. The refusal belongs in
  `coverage_problems`, which already has the PRD ID set.

### F6 — `validation-report.md`: the artifact the client approval rests on is unread

- **Ref** `cli/forge.py:21`, `cli/forge.py:113-114`, `skills/forge-build/references/validation-report-template.md:1-14`
- **Status** verified
- **Severity** major
- **What** The final phase registers one document, checks four headings are non-empty, and
  nothing else. No report row is tied to a `TC-` line, and "Requirements not met" is not
  compared with the PRD IDs.
- **Evidence** `grep validation-report cli/forge.py` → only `REQUIRED`
  (`cli/forge.py:21`) and `HEADINGS` (`cli/forge.py:113-114`). The test cases the report
  should cover are parseable and already parsed elsewhere:
  `re.findall(rf"^- TC-{sid}-\d+", txt, re.M)` (`cli/forge.py:832`). The test-plan side has
  an ID check (`cli/forge.py:841-844`) but the report side has none.
- **Impact** The last gate before delivery accepts four one-line sections. A report that
  says "all tests pass" while a `TC-` line in the plans has no result cell is
  indistinguishable, mechanically, from a complete one. In client mode this document
  feeds the touchpoint summary (`skills/forge-build/SKILL.md:25`), so the client approval
  is the only thing between an unverified report and a delivery.
- **Recommendation** Require one row per `TC-<Sxx>-<n>` found in `.forge/plans/`
  (the set exists at `cli/forge.py:832`), each with a non-empty `Result`; refuse a `B/E/V/L`
  ID of the test plan with no row in "Requirements not met" or in the results table.

### F7 — A screen file with only a purpose and an anatomy table passes registration and the design check

- **Ref** `cli/forge.py:656-697`, `skills/forge-design/references/screen-template.md:7-22`
- **Status** verified
- **Severity** major
- **What** `design_problems` reads the H1, the `- layout:` line, the `## Anatomy` table and
  the `- region-used:` lines. `## Purpose`, `## States`, `## Interactions`, `## Responsive`
  and `## Accessibility` — five of the template's six sections — are never read.
- **Evidence** Harness run on a screen file containing only `# SCR-001 Home`,
  `- layout: LAY-app`, `## Purpose` and `## Anatomy`:
  `headings present in file: ['# SCR-001 Home', '## Purpose', '## Anatomy {#anatomy}']`;
  `structure_problems screen:SCR-001: []`; `register name regex ok: True`;
  `design_problems: []`. An earlier run with `## States / n/a`, `## Interactions / n/a`,
  `## Responsive / n/a`, `## Accessibility / n/a` also returned `[]`.
- **Impact** `skills/forge-design/references/review-checklist.md:6` asks the QA reviewer
  "Does every screen define all six states?" — the artifact the producer fills does not
  contain a place for them, and the CLI cannot see them. v2's `screen.md.tmpl:84` made the
  nine states a mandatory section with a per-state block, and `:162-171` carried the gate
  list. R4's two reviewers are the only remaining check, and a reviewer reading a
  translated screen file has no anchor to look for.
- **Recommendation** Turn States into a parsed table
  (`state | what changes in each zone | copy | primary action`), one row for each of
  `empty, loading, error, offline, partial, success`, and require one row per zone of the
  Anatomy table. One `md_rows(txt, "States")` call (`cli/forge.py:589-599`) plus a header
  check does it.

### F8 — The roadmap gate is a whole-file substring test, so one release can carry every ID

- **Ref** `cli/forge.py:754-763`, `skills/forge-discover/references/roadmap-template.md:7-8`
- **Status** verified
- **Severity** major
- **What** `roadmap_problems` collects every `B/E/V/C/L` ID that appears anywhere in
  `roadmap.md` and compares the set with the live IDs. It never attributes an ID to a
  release, never reads a row, and never checks the "Why in the MVP" column.
- **Evidence** `seen = set(re.findall(rf"\b({ID_RE})\b", txt))` (`cli/forge.py:760`),
  then `live - seen` and `seen - live - gone` (`:761-762`). Harness run with
  `## MVP` / `x`, `## R1` / `x`, `## R2` / `x`, `## Trade-offs` / `x`, `## Coverage` / `x`
  and one line `- B1 E1 V1 C1` under MVP: `roadmap_problems: []` and
  `design_problems: []`. The template leaves `## R1` and `## R2` empty
  (`roadmap-template.md:7-8`), 2 of 5 sections.
- **Impact** The roadmap is a client touchpoint (`cli/forge.py:25`) and the document that
  decides what the MVP is. Its only mechanical property is that the letters of every ID
  occur somewhere in the file. `roadmap-template.md:15` states the real rule ("every ID
  appears above exactly once") and no code implements it.
- **Recommendation** Parse each release as a table (`| Item | Delivers (IDs) | Why in the
  MVP |`) with `md_rows`, then require the union of `Delivers` cells to equal the live ID
  set exactly once, refuse a release with no row, and refuse an empty `Why` cell. This is
  the same shape as the slice coverage check (`cli/forge.py:786-794`).

### F9 — No v3 template carries its own gate checklist; every v2 template did

- **Ref** `skills/forge-discover/references/prd-template.md:1-18`, `skills/forge-architect/references/architecture-template.md:1-25`, v2 counterparts
- **Status** verified
- **Severity** major
- **What** v2 ended each template with a binary "Checklist de gate" the producer could run
  before spending two reviewer rounds. v3 templates end at their last content section, and
  `docs/MIGRATION-v2.md` does not record the removal.
- **Evidence** v2 checklists: `v2-baseline/skills/forge/templates/prd.md.tmpl:187-198`
  (10 items), `roadmap.md.tmpl:125-133` (7), `architecture.md.tmpl:262-273` (10),
  `screen.md.tmpl:162-171` (8), `design-system.md.tmpl:308-341` (21),
  `test-plan.md.tmpl:166-174` (7), `implementation-plan.md.tmpl:261-270` (8), plus
  `v2-baseline/skills/forge/references/review-checklists.md:7-32`. In v3, the last line of
  `prd-template.md` is `- B99 <removed requirement>: reason` (`:18`) and the last line of
  `architecture-template.md` is `## 10. Risks and open questions` (`:25`).
  `docs/MIGRATION-v2.md:5-17` lists 11 changed areas and mentions neither templates nor
  checklists.
- **Impact** Under the repository's own v2-parity rule (`AGENTS.md`, "A capability v2 had
  and v3 lacks is a regression until `docs/MIGRATION-v2.md` records it as removed on
  purpose"), this is an unrecorded regression twice over: the checklist and the standard
  it encoded. A weak model has no self-check; the only feedback is a reviewer's prose,
  which costs a review round (`cli/forge.py:372-380`).
- **Recommendation** Add a final `## Gate {#gate}` block to each template, with one line
  per item naming the command that decides it (I10 style, like
  `rules-report-template.md:18` does for the audit output). Either that, or record the
  removal in `MIGRATION-v2.md` and name the concrete reviewer question that replaces each
  item.

### F10 — The brief leaves the two facts every later phase reads with no shape

- **Ref** `skills/forge-bootstrap/references/brief-template.md:3-4,5,12-13`
- **Status** verified
- **Severity** minor
- **What** Five of nine sections are bare headings, including `Users`, `Deadline and budget
  signals` and `Who answers, and how fast`. `Goal and success measure` merges two distinct
  facts — the goal, and the number that says it was met — into one heading with no body.
- **Evidence** `structure_problems` on the template itself reports 5 empty sections:
  request in the client, goal and success measure, users, deadline and budget signals,
  who answers. `brief-template.md:4` and `:13` carry no body. By contrast `:7`, `:9`,
  `:11`, `:15` name their fields or their one-per-line rule.
- **Impact** The PRD's "Goals and success measures" (`prd-template.md:4`, also empty) is
  written from this section two phases later, so a missing baseline at bootstrap becomes an
  invented target in the PRD and an unverifiable claim at validation. The CLI never asks
  for a number in either document.
- **Recommendation** Split into `## 2. Goal {#goal}` and
  `## 3. Success measure {#success-measure}` with one row
  `| Measure | Baseline | Target | Source |`, and reuse the same table shape in the PRD so
  the value survives the phase boundary. Both sections then need a numeric cell, which
  `cli/forge.py:135-148` can refuse.

### F11 — Test-plan and plan-body checks stop at "the ID is mentioned somewhere"

- **Ref** `cli/forge.py:822`, `cli/forge.py:837`, `cli/forge.py:840-844`
- **Status** verified
- **Severity** minor
- **What** The plan's `## Acceptance` section is checked for its heading only; the
  plans-index for a mention of each slice id; the test plan for a mention of each slice and
  each `B/E/V/L` id. The bodies can be one example row plus prose.
- **Evidence** `for h in ("Serves", "Tasks", "Acceptance", "Test cases")` then
  `if not has_heading(...)` (`cli/forge.py:822-824`) — presence only for all four, then
  content checks only for `serves` (`:828`), task count (`:825`) and `TC-` (`:832`).
  `plans-index does not list {sid}` fires on `re.search(rf"\b{sid}\b", itxt)`
  (`cli/forge.py:837`); the test-plan equivalents are `:840` and `:843`. Harness run:
  `plans_problems` on a plan whose Acceptance body is `x` and a test plan whose only row
  is the template's single example (`test-plan-template.md:9`) reported only missing `E1`,
  `L1`, `V1` mentions.
- **Impact** `forge-plan/SKILL.md:3` promises a plan "precise enough for a weaker model to
  execute without guessing". The three quantities a weaker model needs — acceptance
  criterion per ID, a coverage row per ID, an order in the index — are each satisfied by a
  mention.
- **Recommendation** Require one Coverage-matrix row per live `B/E/V/L` ID with a
  non-empty `Test case` cell that matches a `TC-` line of the named slice, and one
  numbered acceptance item per ID in `## Acceptance`.

### F12 — `design-references` requires a client-only section in interactive mode

- **Ref** `cli/forge.py:104-105`, `skills/forge-design/SKILL.md:26`
- **Status** verified
- **Severity** minor
- **What** `directions presented to the client` is a required non-empty section of
  `design-references` in every mode, while D5 makes the two-or-three directions a client
  mode step.
- **Evidence** `HEADINGS["design-references"]` includes the key (`cli/forge.py:104-105`),
  and `structure_problems` refuses an empty body (`cli/forge.py:146-147`). D5:
  "**D5 Client touchpoint.** In client mode, present two or three visual directions in
  plain language" (`skills/forge-design/SKILL.md:26`).
- **Impact** An interactive project must either fabricate a client section or leave the
  register refused. It is a small hole, but it is the kind a weak model resolves by
  inventing content, which is the one thing BS2 forbids
  (`skills/forge-bootstrap/SKILL.md:21`).
- **Recommendation** Make the section conditional on `mode == "client"` in
  `structure_problems`, or reword D5 to require the directions in every mode and say what
  changes in client mode (who chooses).

## The PRD

The PRD is 18 lines, 4 of them empty. It is the only deliverable whose ID universe every
other phase depends on, and the only one whose content check is a regex for `^- <ID>`
(`cli/forge.py:745`).

| # | Section (line) | Body in template | What the CLI does | Class |
|---|---|---|---|---|
| 1 | Problem and audience (`:3`) | none | non-empty only | vacuous |
| 2 | Goals and success measures (`:4`) | none | non-empty only | vacuous |
| 3 | Business rules (`:5-6`) | `- B1 <rule> (source: …)` | ID unique, live, not reused (`:745-748`) | checked (ID only) |
| 4 | Edge cases (`:7-8`) | `- E1 <case and expected behavior>` | ID only | checked (ID only) |
| 5 | Validations (`:9-10`) | `- V1 <input rule and error behavior>` | ID only | checked (ID only) |
| 6 | Constraints (`:11-12`) | `- C1 <constraint>` | ID only | checked (ID only) |
| 7 | Legal requirements (`:13-14`) | `- L1 … (obligation: OB-<n>)` | `L`↔`OB` both directions (`:1381-1390`) | checked |
| 8 | User stories (`:15`) | none | non-empty only | vacuous |
| 9 | Open questions (`:16`) | none; the heading carries "(each with an owner and a deadline)" | non-empty only | vacuous |
| 10 | Out of scope (`:17-18`) | `- B99 <removed requirement>: reason` | live/withdrawn split (`:732`), no ID reuse (`:748`) | checked |

Demonstration that the whole phase is satisfiable at 514 bytes: a PRD with `x` under
sections 1, 2, 8 and 9 and one `<placeholder>` ID line under 3–7 and 10 returned
`structure_problems: []`, `prd_problems: []`, `compliance_prd_problems: []`,
`coverage_problems: []` and `roadmap_problems: []`. The topic sentence, the audience, the
user stories and the open questions were the literal string `x`. A 335-byte earlier
variant differed only in also failing coverage until `L1` was listed in the one-row
`roadmap.md` and `slices.md`.

What a rigorous PRD needs that v3 does not ask for — and what the CLI could take:

| Need | v3 asks? | CLI can check? | How | Reviewer only |
|---|---|---|---|---|
| Personas with role, context, permissions | no — v2 did (`prd.md.tmpl:38-42`) | yes | each `role` of `screen-map.md` appears as a persona row; a permissions cell per persona | adequacy of the role split |
| User stories with acceptance criteria | no (empty section) — v2 did (`prd.md.tmpl:46-61`) | partly | `US-<n>` block with ≥1 acceptance line and ≥1 `B/E/C` reference; every `B` in ≥1 story | story quality |
| Non-functional requirements: performance, availability, i18n, a11y, retention | no — v2 did (`prd.md.tmpl:95-115`) | yes | one row per dimension, each `Measure` cell holding a number and a unit | whether the threshold is right |
| Success metric with baseline and target | heading only, no shape; v2 had `prd.md.tmpl:161-165` | yes | table `Measure · Baseline · Target · Window`; refuse `n/a` or empty baseline | relevance of the metric |
| Assumptions and risks | no — v2 did (`prd.md.tmpl:119-127`) | partly | table with `Mitigation` non-empty and ≥1 assumption row | whether the risk is the real one |
| Dependencies | no | yes | each dependency also appears in `architecture.md` "External integrations" | — |
| Data classes and sensitivity | no | yes, cross-file | table `class · fields · sensitivity · retention`, and each class cited by an `L` or a `B`; pairs with the register's `topics` (`cli/forge.py:1369-1370`) | lawfulness of the classification |
| Glossary | no — v2 had `prd.md.tmpl:169-173` | partially | presence + table shape | term accuracy |
| Release mapping | yes, via the roadmap (`cli/forge.py:754-763`) | yes, but only by substring (F8) | per-release rows | — |
| Measurable acceptance per requirement | no | yes | each live ID must appear in a plan `TC-` line (the set exists, `:832`) and again in the validation report (F6) | — |
| Open questions with owner and deadline | heading text only | yes | `Question · Owner · Due` columns; a due date that parses; no open row surviving validation | resolving them |

Nine of these ten are mechanically checkable with functions the CLI already has (ID sets,
`md_rows`, cross-file equality). Only "is this the right metric" and "is this risk real"
are reviewer-only. One pairing is available at the PRD gate: data classes ↔ the
compliance register's `topics`, because `compliance` runs before `prd` (`PHASES`,
`cli/forge.py:8-9`). The persona ↔ `screen-map` role pairing is not: `screen-map.md` is
produced in `design`, two phases later, so that check belongs to the design gate, not the
PRD gate.

`skills/forge-discover/SKILL.md:26-34` — the producer's full instruction for the PRD — is
9 lines and names none of them: no personas, no acceptance criteria, no non-functional
requirement, no metric, no risk, no glossary. The empty sections are therefore not a
template defect alone; the skill has nothing to fill them with.

## Proposed section lists

**PRD — 18 parsed headings.** Keep the 10 existing keys (translated deliverables carry
anchors, `skills/forge/SKILL.md:23`) and add the 8 marked `+`. Adding required sections is a
breaking change for an installed project: `structure_problems` would refuse an existing
`prd.md`. Record the migration in `MIGRATION-v2.md` and accept the old set for one version,
or land it with the next state `VERSION` bump (`cli/forge.py:7`, `:73-74`).

| # | Heading | Shape | Check and refusal |
|---|---|---|---|
| 1 | `## 1. Problem and audience {#problem-and-audience}` | 3 paragraphs + `Evidence:` line | non-empty; `Evidence` names a landscape row or `user-stated` |
| 2 | `+ ## 2. Personas {#personas}` | `id · role · context · technical level · permissions · frequency` | ≥2 rows, one of them non-user (admin or support); at the design gate, every `role` of `screen-map.md` has a persona row |
| 3 | `## 3. Goals and success measures {#goals-and-success-measures}` | `Goal · Measure · Baseline · Target · Window` | numeric `Target`, non-empty `Baseline` |
| 4 | `## 4. Business rules {#business-rules}` | `- B<n> <rule> (source: …)` | unique, live, ≥8 chars of text after the ID |
| 5 | `## 5. Edge cases {#edge-cases}` | `- E<n> <case> → <expected>` | unique; a `→` or `expected:` marker |
| 6 | `## 6. Validations {#validations}` | `- V<n> <input rule> → <error>` | unique; an error marker |
| 7 | `+ ## 7. Data classes {#data-classes}` | `class · fields · sensitivity · retention · lawful basis` | each class cited by an `L` or `B`; sensitivity in a closed set; each class maps to a register `topic` |
| 8 | `## 8. Constraints {#constraints}` | `- C<n> <constraint>` | unique |
| 9 | `+ ## 9. Non-functional requirements {#non-functional}` | `dimension · requirement · measure · verification` | all six dimensions present; a number in each `measure` |
| 10 | `## 10. Legal requirements {#legal-requirements}` | `- L<n> … (obligation: OB-<n>)` | unchanged, `cli/forge.py:1381-1390` |
| 11 | `## 11. User stories {#user-stories}` | `US-<n>` block: role, want, benefit, `- [ ]` acceptance lines, `serves:` IDs | ≥1 acceptance line, ≥1 live ID |
| 12 | `+ ## 12. Dependencies {#dependencies}` | `dependency · type · owner · needed by · status` | each row appears in `architecture.md` at the architecture gate |
| 13 | `+ ## 13. Risks and assumptions {#risks}` | `id · risk or assumption · probability · impact · mitigation · owner` | `mitigation` non-empty |
| 14 | `## 14. Open questions {#open-questions}` | `question · owner · due · answer` | `due` parses as a date; no open row at validation |
| 15 | `+ ## 15. Glossary {#glossary}` | `term · definition` | ≥1 row; every ALL-CAPS acronym of the ID lines defined |
| 16 | `+ ## 16. Acceptance {#acceptance}` | `ID · acceptance statement · verification command` | every live ID has a row; each row names a command |
| 17 | `## 17. Out of scope {#out-of-scope}` | `- B<n> <removed requirement>: reason` | unchanged, `cli/forge.py:732,748` |
| 18 | `+ ## 18. Release mapping {#release-mapping}` | `ID · release` | each live ID once; release is an `H2` of `roadmap.md` |

**The four templates that carry the most leverage, beyond the PRD.** Each addition uses a
parser that already exists (`md_rows`, `has_heading`, set equality) and each refusal names
the section and the line.

| Template | Add | Enforced by |
|---|---|---|
| `architecture-template.md` | per-entity table, per-endpoint table, ADR row (`decision`, `options`, `reason`, `C<n>`) | `coverage_problems` (`cli/forge.py:778-795`) |
| `design-system-template.md` | parse the colors table; require a token per cited name in `screens/*.md` | `design_problems` (`cli/forge.py:629-701`) |
| `validation-report-template.md` | one row per `TC-` of the plans, `Result` non-empty; one row per unmet ID | a new `validation_problems` beside `plans_problems` |
| `screen-template.md` | `## States` as a 6-row table, one row per state, columns per zone | `design_problems` via `md_rows(txt, "States")` |

The minimum that buys the most, if only one change lands: parse the PRD's personas,
success-metric and NFR tables, because every later deliverable already keys on the ID
universe the PRD defines and none of the three is currently asked for anywhere.

## Rejected candidates

Things that looked vague and are not:

| Candidate | Why it is not a finding |
|---|---|
| `landscape-template.md` (23 lines) | Every section is shaped: a 7-column products table (`:12-13`), `- INV-1:` bullets (`:16`), a verdict column that must be `keep/drop/differ` (`:19`), and the skill makes the verdict mandatory (`skills/forge-discover/SKILL.md:21`). 0 empty sections. |
| `register-template.md` (21 lines) | The most parsed structure in the kit: 9 columns (`cli/forge.py:1300`), 8 refusals per row (`:1344-1365`), market and topic coverage (`:1366-1370`), freshness by date (`:1358`). Short because the form is dense, not because it is loose. |
| `plan-template.md` (17 lines) | 5 mechanical checks on 5 sections: `serves` equality (`cli/forge.py:828-831`), 1–15 tasks (`:825-827`), a `TC-` line (`:832`), 4 headings (`:822`). The strictest template in the kit. Its gap is `## Acceptance` (F11), not the template. |
| `slices-format.md` (12 lines) and `plans-index-template.md` (5 lines) | Format specs, not prose forms: the slice columns are parsed (`cli/forge.py:766-775`) and cross-checked against the PRD ID set both ways (`:786-794`). Their shortness is a feature. |
| `hierarchy.md`, `formats.md`, `review-checklist.md` | Specifications the parsers and reviewers read, not deliverable forms. `formats.md:1` states it is the exact format `forge design check` parses, and it matches (`:3-18`). |
| `rule-file-template.md` (199 lines), `target-formats.md`, `workflow.md` | Generator library gated by 10 `rules_checks` (`cli/forge.py:1040-1182`) including budget, index, placeholders, cross-references and contamination — the most heavily enforced layer in the kit. |
| "Empty sections are silently accepted" | False for the 12 registered names: `structure_problems` refuses them (`cli/forge.py:145-147`), which is why 5 brief sections and 4 PRD sections fail a verbatim copy. The defect is that one character satisfies the check, not that the check is absent. |
| `forge template roadmap` printing `## 1. Mvp` and `## 1. Api contracts` | Harmless: release names are compared lowercased (`cli/forge.py:640,646`), and the anchors match the templates. It is a naming inconsistency, not a quality hole. |

## Open questions

1. Was dropping the per-template gate checklists a decision? `docs/MIGRATION-v2.md:5-17`
   does not say, and the v2-parity rule in `AGENTS.md` treats silence as a regression.
   Only the author can confirm. *(unverified)*
2. Is `forge template` meant to be used by models, or only cited for anchors? The only
   skill reference is R6 (`skills/forge/SKILL.md:23`), which uses it for anchors; all seven
   test helpers use it as a file source. F1 depends on which one is intended. *(unverified)*
3. Would adding PRD sections break a live lab? `structure_problems` refuses a missing
   section, so yes for any project mid-flight — the answer decides whether this ships
   behind a `VERSION` bump. *(inferred from `cli/forge.py:139-147`)*
4. Do the two reviewers reliably catch `<rule>`-style placeholders (F2)? No suite tests a
   reviewer's judgement, and `forge review record` (`cli/forge.py:401-449`) only validates
   the report's shape. *(cannot verify without a live review run)*
5. `tests/templates.sh` is the only check tying CLI to templates, and it compares heading
   names only (`tests/templates.sh:15-20`). Is another suite meant to register a template
   copy? No suite does today; the `sed 's/<fill>/sample text/'` helpers use the stub, so
   the reference templates are never exercised. *(verified by grep over `tests/`)*
