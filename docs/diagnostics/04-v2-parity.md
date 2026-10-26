# v2 to v3 parity: what the rebuild lost, kept and improved

## Scope and method

Both sides were inventoried by walking the trees, not by reading their claims.

| Side | Command | Result |
|---|---|---|
| v2 | `git ls-files` in `~/AppData/Local/Temp/opencode/v2-baseline` | 115 files, 77 Markdown, 19 JavaScript, 2 workflows, no tests directory |
| v3 | `git ls-files` in the repository | 120 files, 96 Markdown, 14 test suites + `install.sh` + `.devcontainer/post-create.sh`, one Python CLI (1629 lines) |

Then, for each candidate capability, both implementations were opened and read: the v2
`skills/forge/SKILL.md` (1289 lines) and its 11 references, the 11 v2 agents, the scripts
under `scripts/` and `skills/*/scripts/`, `.github/workflows/*`, `package.json`, `VERSION`,
`CHANGELOG.md`; against `cli/forge.py`, the 10 v3 skills, the 9 v3 agents, the 14 v3
suites, the 2 hooks, `scripts/install.py` and `docs/`.

v2 path convention in the tables below: `agents/`, `references/`, `templates/` and every
script except the release tooling live under `skills/forge/`; `scripts/validate-repo.js`,
`release*.js`, `snapshot*.js`, `changelog-policy.js` and `check-workflows.py` are at the v2
repository root. v3 paths are repository-relative.

Rules applied:

- A capability counts as `removed on purpose` only when `docs/MIGRATION-v2.md` says so; the
  citing line is given.
- A capability v2 had, v3 lacks, and no migration line covers, is classified `regressed`
  even when a v3 document states the absence as a fact (see F1, F2): a statement of the
  defect is not a decision about it.
- `AGENTS.md:34-47` is the repository's own rule for this audit ("A capability v2 had and v3
  lacks is a regression until `docs/MIGRATION-v2.md` records it as removed on purpose with
  the reason. Silence is a regression."). Every regression below is judged against it.
- The suites were read, not executed: `AGENTS.md:73-75` and `docs/STATUS.md:5` require POSIX,
  and this session runs on native Windows. Every "test exists" claim is a static reading of
  the suite file.

### Test coverage parity

`docs/ESCAPE-HATCH-AUDIT.md:7-24` lists 16 shortcuts v3 closes, each with a named case. The
table below checks that each case exists and that at least one of them is a mutation (the
shortcut attempted against a working fixture, not merely asserted in prose).

| # | v3 shortcut closed by | Case in the suite | Mutation? |
|---|---|---|---|
| 1 | sealed `state.json` | `tests/adversarial.sh:24-33` (hand-edit, then git-restore) | yes |
| 2 | DRIFT on an approved deliverable | `tests/adversarial.sh:61-64` | yes |
| 3 | reopen needs a reason | `tests/adversarial.sh:65-68` | yes |
| 4 | phase order / early deliverable | `tests/adversarial.sh:52-53`, `tests/e2e.sh:29-30` | yes |
| 5 | two reviewers | `tests/adversarial.sh:44-49` | yes |
| 6 | review of an older version | `tests/adversarial.sh:56-58` | yes |
| 7 | report path and report hash | `tests/adversarial.sh:69-72`, `:73-78` | yes |
| 8 | dismissal needs a decision | `tests/adversarial.sh:79-89` | yes |
| 9 | `auto` approval / mode switch | `tests/adversarial.sh:69-70`, `tests/e2e.sh:40,48,52` | yes |
| 10 | `slice done` evidence shape | `tests/flow.sh:66-67` | yes |
| 11 | placeholders at registration | `tests/adversarial.sh:90-91` | yes |
| 12 | edited installed kit | `tests/install.sh:26-29,36,62` | yes |
| 13 | requirement coverage | `tests/flow.sh:24-26`, `tests/audit.sh:54-64` | yes |
| 14 | layout region with no task | `tests/design.sh:48-52` | yes |
| 15 | two screens in one file, H1 | `tests/design.sh:34-39` | yes |
| 16 | vague rule set | `tests/rules.sh:36-52` (15 mutations for 10 checks) | yes |

Verdict: every v3 closed shortcut has a mutation test. The gap is not in the tests that
exist; it is in the checks v3 no longer has (F1, F5, F9, F10, F11).

## Parity matrix

Severity applies only to `regressed` rows.

| # | Capability | v2 evidence | v3 evidence | Classification | Severity |
|---|---|---|---|---|---|
| 1 | Repository-wide validator (front matter, portable ids, name=dir, dangling skill refs, declared lists vs files, unrendered placeholders, script syntax, stray characters, hints→commands, agent dispatch) | `scripts/validate-repo.js:156-721` | no equivalent; admitted at `AGENTS.md:45-47` | regressed | critical |
| 2 | CI enforcement of the repository's own checks | `.github/workflows/ci.yml:1-79` (validate-repo, selftest, VERSION/CHANGELOG, release smoke, snapshot smoke, changelog policy, workflow syntax) | no `.github/` in `git ls-files` | regressed | critical |
| 3 | Self-tests of the kit's own claims (skills exist, agents declare contracts, references resolve) | `skills/forge/scripts/selftest.js` (5679 lines, 368 `test(` call sites), `skills/project-rules-architect/scripts/selftest.js` (286) | 14 suites test the CLI; none asserts the kit's own claims (`tests/templates.sh:8-20` covers 12 template names only) | regressed | major |
| 4 | Mutation tests for each checker | `selftest.js` builds broken fixtures per check (see `CONTRIBUTING.md:17-25` in v2) | `tests/design.sh:34-52`, `tests/rules.sh:36-52`, `tests/adversarial.sh` | ported | – |
| 5 | Release artifact, VERSION, CHANGELOG | `scripts/release.js`, `scripts/snapshot.js`, `VERSION:1` (1.14.0), `CHANGELOG.md` (2496 lines), `scripts/changelog-policy.js` | none; `scripts/install.py:213` records scope/targets, no version | regressed | major |
| 6 | Workflow YAML + bash syntax check | `scripts/check-workflows.py:1-103`, `ci.yml:62-79` | none | regressed | minor |
| 7 | Impact protocol for a change after approval (11-dimension map, severity, explicit confirmation, stale marking, cascade rule) | `skills/forge/SKILL.md:973-1003`, `skills/forge/references/impact-protocol.md:8-131` | only `forge phase reopen` (`cli/forge.py:889-907`); one contract heading "changes after approval" (`cli/forge.py:96`) | regressed | major |
| 8 | Per-document review checklists (10 documents) | `skills/forge/references/review-checklists.md:7-157` | one checklist, design only (`skills/forge-design/references/review-checklist.md:1-12`) | regressed | major |
| 9 | Measured design checks (WCAG 1.4.3/1.4.11 contrast, tokens without value, component↔screen parity) | `skills/forge/scripts/design-check.js:57-68,470,516,774` | `cli/forge.py:629-701` reads layouts, screen-map and screens; never reads `design-system.md` | regressed | major |
| 10 | Anti-generic design interdits (14 blocking rules + "one divisive choice" + density) | `skills/forge/references/design-quality.md:60-134` | references/mood/anti-references templates only (`skills/forge-design/references/design-references-template.md:1-12`) | regressed | major |
| 11 | Screen specification depth (9 states, data section, ID traceability, visual direction per screen) | `skills/forge/templates/screen.md.tmpl:23-162` | `skills/forge-design/references/screen-template.md` (6 states, no data or traceability section) | regressed | major |
| 12 | Business scenario tests (lifecycle, injected clock, final invariant, never write what the app writes) + `scenario-tester` agent | `references/scenario-tests.md:1-186`, `agents/scenario-tester.md:1-56` | `skills/forge-plan/references/test-plan-template.md:5` (four levels, one line each) | regressed | major |
| 13 | Test-strategy selection (7 families, measured pitfalls, per-stack) | `references/test-strategies.md:20-113` | same one line as row 12 | regressed | major |
| 14 | Test-plan content (coverage obligations per ID type, foundation tests, minimal regression suite, environment matrix, gate checklist) | `templates/test-plan.md.tmpl:15-166` | `skills/forge-plan/references/test-plan-template.md:1-14`; the CLI checks ID and slice coverage (`cli/forge.py:838-844`) | regressed | major |
| 15 | DDL executed, or not written | `scripts/ddl-exec.js:478-577`, `SKILL.md:782-819` | `architecture-template.md` §5 is prose ("Entities, fields with types…"); no SQL, no execution | regressed | major |
| 16 | Dependency cycle detection + topological order | `scripts/dependency-check.js:116-155`, `SKILL.md:757-776` | graph requested by `skills/forge-architect/SKILL.md:23`, never parsed or checked | regressed | major |
| 17 | Cross-artifact consistency (screen↔slice, nav↔screen, citation accuracy, section references, plan self-consistency) | `scripts/consistency-check.js:307-368,1062,1267` | `cli/forge.py:778-845` (coverage, premises, plans) covers ID traceability only | regressed | major |
| 18 | Slice exit criteria executed (project commands, ≥1 real test case) | `scripts/forge-exit.js:1-23` | `cli/forge.py:881-882` matches `<cmd> : <result>` on the evidence string | regressed | major |
| 19 | Post-run audit loop (mandatory incident types, `origin` field, metrics, cross-project structural analysis, finding→rule promotion) | `SKILL.md:1101-1145`, `scripts/audit-report.js:216-249,427`, `state.js:2312` (`finding`) | journal + `forge memory log`; no origin, no metrics, no aggregation, no promotion field | regressed | major |
| 20 | Product interview protocol (8 categories, probing rules, alarm signals, closing summary) | `agents/product-analyst.md:28-101` | `skills/forge-discover/SKILL.md:30` (one line) | regressed | major |
| 21 | Premise challenger as a dedicated contract (attack grid, triggers, one critical blocks) | `agents/premise-challenger.md:36-118` | `skills/forge-discover/SKILL.md:16` invokes "`forge-redteam` in challenge mode"; `agents/forge-redteam.md` defines no such mode | regressed | major |
| 22 | Archetype standards + measured pathologies | `references/archetypes.md:35-241` (8 archetypes, per-archetype pathologies, comparison grid) | `skills/forge-design/references/hierarchy.md:16-27` (9 starting orders); the word "archetype" is now one template field | regressed | major |
| 23 | Stray-character scan with an allow-list (kit sources) | `SKILL.md:1223-1252`, `validate-repo.js:520` | none | regressed | major |
| 24 | Verification-discipline corpus (14 rules) | `SKILL.md:1146-1180` | absent from `skills/`, `agents/`, `AGENTS.md` | regressed | major |
| 25 | Module prioritization (frequency × centrality, 5 steps, recorded navigation order) | `references/module-prioritization.md:13-127`, `state.js:2309` (`set-nav`) | H4 + pattern table (`hierarchy.md:9,16-27`); nav order is a design-system heading with no record and no check | regressed | minor |
| 26 | Research discipline (6 questions, warning-list form, anti-goals, output control) | `references/research-protocol.md:15-113` | landscape template 6 sections (`skills/forge-discover/references/landscape-template.md`), invariants kept | regressed | minor |
| 27 | ID amendment protocol (extend, never renumber) | `state.js:2285` (`amend`), `SKILL.md:450-486` | PRD IDs checked (`cli/forge.py:738-751`); slice IDs not, `slices.md` `## Removed` never parsed (`cli/forge.py:766-775`) | regressed | minor |
| 28 | Fast Track (automatic phases 4-5) | `references/fast-track.md:1-354`, `SKILL.md:1022-1050` | absent | removed on purpose | `MIGRATION-v2.md:11` |
| 29 | Forge ↔ project-rules-architect boundary contract | `references/skill-boundaries.md:1-160` | one rules phase inside Forge | removed on purpose | `MIGRATION-v2.md:17` |
| 30 | `state.json` v2 schema + front-matter mirror | `references/state-schema.md:1-255`, `state.js:2306` (`sync`) | sealed state, one status per item | removed on purpose | `MIGRATION-v2.md:9` |
| 31 | Multi-perspective validation | `SKILL.md:1005-1050` (guided rotation, optional) | `skills/forge/SKILL.md:21` (R4) + `cli/forge.py:498-507` (two hash-bound reviews, mandatory) | improved | – |
| 32 | Independent reviewers on every deliverable | Fast Track only (`SKILL.md:1052-1070`) | CLI refuses without `qa` and `redteam` on the current hash | improved (`MIGRATION-v2.md:13`) | – |
| 33 | Kit integrity | `forge-guard.js kit-integrity` (`SKILL.md:1210-1211`) | `forge kit verify` + `status` warn + `gate approve` refusal (`cli/forge.py:523-525`) | improved | – |
| 34 | Requirement coverage / withdrawn premises | `coverage-check.js`, `consistency-check.js:446` | `cli/forge.py:778-810`, gated at architecture/roadmap (`:458-473`) | improved | – |
| 35 | Client touchpoints | `client-liaison` agent, prose only | CLI-enforced per touchpoint (`cli/forge.py:526-537`, `tests/e2e.sh:52-62`) | improved (`MIGRATION-v2.md:16`) | – |
| 36 | Rules generator | `project-rules-architect` + Node audit | `forge-rules` + `forge rules audit` in the gate (`cli/forge.py:1040-1211`) | improved (`MIGRATION-v2.md:17`) | – |
| 37 | Installation | `npx skills add` | `scripts/install.py`, two scopes, hash manifest, uninstall (`tests/install.sh`) | improved | – |
| 38 | Loop guard | `state.js fast-track --attempt` (3 tries) | attempts ledger, STUCK at 5, ESCALATE at 3 rounds (`tests/loops.sh`) | improved | – |
| 39 | Regulatory phase | none | `compliance` phase, register, rechecks (`tests/compliance.sh`) | improved (`MIGRATION-v2.md:15`) | – |
| 40 | Early deliverable / stray path / placeholder guards | `forge-guard.js:1187` | `cli/forge.py:322-352`, `tests/adversarial.sh:50-53,90-91` | ported | – |
| 41 | Evidence-bound approval | prose instruction | `--evidence`, `--user-evidence`, journaled verbatim (`cli/forge.py:521-546`) | improved | – |
| 42 | Template ↔ checker sync | `validate-repo.js` declared-lists check | `tests/templates.sh:8-20` | ported | – |
| 43 | Multi-tool distribution (30+ agents via `npx skills add`) | `README.md:1-22` (v2) | Claude Code + OpenCode only; `docs/STATUS.md:39` marks the `npx skills add` layout untested | regressed | minor |

Counts: 43 rows — 3 ported, 10 improved, 3 removed on purpose, 27 regressed (2 critical, 20 major, 5 minor).

## Findings

### F1 — The repository has no validator for its own references
- Ref: matrix 1
- Status: verified
- Severity: critical
- What: v2 shipped `scripts/validate-repo.js` (740 lines, 16 named checks). v3 ships nothing. Nothing fails when a skill cites a file that no longer exists, when a skill folder and its `name` disagree, when an agent named by a skill is absent, when `skills/` gains a folder the installer or README does not know, or when a reference file is orphaned.
- Evidence: `scripts/validate-repo.js:156-721` defines `no_root_skill_md`, `skills_directory_exists`, `every_skill_has_frontmatter`, `frontmatter_is_strict_yaml`, `skill_ids_are_portable`, `skill_name_matches_directory`, `every_skill_has_description`, `descriptions_are_actionable`, `no_dangling_skill_references`, `no_skill_id_typos`, `declared_lists_match_files`, `no_unrendered_placeholders`, `scripts_parse`, `no_stray_characters_in_skill_source`, `hints_point_to_real_commands`, `agent_dispatch_matches_skill`. In v3, `AGENTS.md:45-47` states "v3 ships no CI and no repository-wide validator. Nothing catches a broken reference except the suites and `tests/templates.sh`". `tests/templates.sh:8-20` checks 12 template names against `forge.HEADINGS` and nothing else. `docs/AUDIT-2026-10-19.md:7` records a reference graph built over 94 files; `:15` records that eleven deliverable names had no template.
- Impact: the v2 file exists because each defect it checks had already shipped (its own header, `:9-20`). Today the 10 skills, 9 agents, 66 reference files and 17 template files have no reference graph, and the installer globs the folders (`scripts/install.py:172-173`), so a renamed reference is installed broken and only a model's reading finds it. `docs/STATUS.md:39` notes `npx skills add` conformance is untested; the check that enforced portable ids and strict YAML is the one that went away.
- Recommendation: add `forge kit lint` (or `python3 scripts/validate_repo.py`) porting all 16 checks, with one mutation per check in a new `tests/repo.sh`, a row in `docs/ESCAPE-HATCH-AUDIT.md`, and a line in `docs/MIGRATION-v2.md` if any check is deliberately dropped. Cheap first slice: the four reference-graph checks, which would have caught `docs/AUDIT-2026-10-19.md:22-29` mechanically.

### F2 — CI is gone, so none of the 14 suites runs on push
- Ref: matrix 2, 6
- Status: verified
- Severity: critical
- What: v2's `.github/workflows/ci.yml` ran the validator, both selftests, the VERSION/CHANGELOG coherence check, the release and snapshot smoke tests, the changelog policy, and a YAML+bash syntax job. v3 has no `.github/` directory.
- Evidence: v2 `.github/workflows/ci.yml:8-79`; `package.json:14-19` wires `npm test` to the validator, both selftests and the two smoke tests (but not the changelog policy). v3: `git ls-files` returns no `.github/` entry; `README.md:52-57` tells a human to run the loop by hand ("Run all thirteen before every change" — the list omits `i18n.sh`, `AGENTS.md:188-191`). `docs/STATUS.md:5` counts "thirteen suites" while `tests/` holds 14.
- Impact: a regression lands silently. The suites cannot be run on native Windows (`AGENTS.md:73-75`), and the repository's documented development environment is a devcontainer (`.devcontainer/`), so a Windows-only contributor has no way to run them locally *and* no CI to fall back on. The two known traps in `AGENTS.md:168-194` (reopen not resetting slices, `forge-memory` claiming an automatic journal entry) are exactly the class of defect a push-triggered suite would surface.
- Recommendation: reinstate a minimal workflow: the 14 suites on `ubuntu-latest`, `python3 cli/forge.py lint-rules`, `tests/templates.sh`, and whatever F1 adds. Until then, add `docs/MIGRATION-v2.md` line stating CI is removed on purpose and why, so the next audit does not have to re-derive it.

### F3 — The change-impact protocol was dropped and reopen is not its equivalent
- Ref: matrix 7
- Status: verified
- Severity: major
- What: v2 required, for any change requested after a document was approved, an 11-dimension impact map, a severity level, an explicit user confirmation, then stale-marking and downstream propagation with a "one change at a time" cascade rule. v3 replaces it with `forge phase reopen <phase> --reason`, a journal entry and a decision line.
- Evidence: v2 `skills/forge/SKILL.md:973-1003` and `references/impact-protocol.md:26-131`; the incriminated outcomes it prevents are at `:104-120` (mark impacted documents `stale`, recompute hashes, check dependent slices). v3: `cli/forge.py:889-907` resets `phases` and later deliverables' reviews, writes a decision and stops; it never touches `s["slices"]`. `skills/forge-bootstrap/SKILL.md:15` reduces change handling to "(`forge phase reopen`)", and `cli/forge.py:96` makes "changes after approval" a contract heading with no procedure behind it. `tests/flow.sh:69` reopens `prd` after `S01` is `done` and never asserts the slice state.
- Impact: reopening `plans` or `architecture` leaves every build slice `done`; the build gate only reads `s["slices"]` (`cli/forge.py:478-483`), so the project advances to validation with slices built against a superseded plan. `AGENTS.md:172-176` records this as a live trap and tells the operator to audit `state.json` by hand — the protocol that made the audit unnecessary is the one that was removed.
- Recommendation: two separate changes. (a) `cmd_reopen` resets `s["slices"]` to `pending` for phases at or before `build`, and `tests/flow.sh` asserts it. (b) Reinstate a change-impact deliverable or a `forge change` subcommand that records the impacted IDs, derives the required reopens, and refuses `gate approve` while any impacted downstream deliverable is still approved on a stale premise.

### F4 — Reviewers lost their per-document checklists
- Ref: matrix 8
- Status: verified
- Severity: major
- What: v2 gave each of 10 deliverables its own gate checklist (PRD, roadmap, benchmarks, design system, screens, architecture, implementation plan, test plan, Fast Track output, post-implementation), each with concrete, checkable questions. v3 gives the reviewers one role-level mandate and one design checklist.
- Evidence: v2 `references/review-checklists.md:7-157` — for the PRD alone, 13 items including "Chaque user story suit le format … avec critères d'acceptation vérifiables" and "Aucun jargon technique d'implémentation". v3 `agents/forge-qa.md:15` asks "every requirement from earlier phases has a place here, every edge case has a behavior, every term is defined, every list is complete, nothing is left as a placeholder"; `agents/forge-redteam.md:14-16` lists three generic probes. The only per-document checklist is `skills/forge-design/references/review-checklist.md:1-12`, and the two reviewers must be told about it in the delegation header (`AGENTS.md:177-179`, known trap).
- Impact: the CLI proves two reviews exist on the right hash; it cannot prove they asked the right questions. A `prd` review that returns `{"findings":[]}` is accepted (`tests/adversarial.sh:19,46` uses exactly that fixture). The concrete PRD/architecture/plan questions that made an empty report credible are gone, and with ten deliverables on one mandate the reviewer's answer quality now depends entirely on the model.
- Recommendation: move the v2 checklists into `skills/forge-<phase>/references/review-checklist.md`, one per producing skill, and make `forge review begin` print (or require) the checklist path for that deliverable's phase, as the design phase already does.

### F5 — Design measurement was replaced by a column the author fills in
- Ref: matrix 9
- Status: verified
- Severity: major
- What: v2 computed WCAG contrast ratios from the token values, flagged tokens without a value, and compared component definitions against their use in screens. v3 keeps the "Contrast on its background" column in the template and checks nothing.
- Evidence: v2 `scripts/design-check.js:50-68` (`relativeLuminance`, `contrast`, `TEXT_AA = 4.5`, `NON_TEXT_AA = 3.0`), plus the `tokens` (`:470`), `tokens-used` (`:516`) and `component-parity` (`:774`) checks; its header (`:10-27`) records that "les ratios sont donc **écrits** par l'auteur" and that three of them were false (7,1 for 7,07, 5,6 for 5,37). v3 `cli/forge.py:629-701` reads `layouts.md`, `screen-map.md`, `roadmap.md` and `.forge/design/screens/*.md`; `design-system.md` is never opened. `cli/forge.py:105-106` declares six headings and `:135-146` requires each present and non-empty at registration, nothing more. `skills/forge-design/SKILL.md:15` nevertheless states "A token with no value is a defect".
- Impact: the exact defect v2 measured is now unobservable: `#FFFFFF` text on `#FFFFFF` passes, a ratio of 7.1 can be invented, and a component can be redefined on two screens. The skill's sentence is a request, not a gate, which `AGENTS.md:84-87` (invariant I10) calls a defect in its own right.
- Recommendation: port the three checks into `forge design check` (`tokens`, `contrast`, `component-parity`), with a mutation per check in `tests/design.sh` (a 4.4:1 pair, a token with an empty value, a component used with two different definitions) and an ESCAPE-HATCH row. Until then, remove the "Contrast on its background" column from `design-system-template.md` rather than let it claim a measurement.

### F6 — The anti-generic design rules are gone; the screen template shrank from 10 sections to 6
- Ref: matrix 10, 11
- Status: verified
- Severity: major
- What: v2 carried a blocking list of 14 design defects, a "one divisive choice" requirement, and a 10-section screen template (visual direction, 9 states, data, ID traceability). v3 requires three reference products, three mood words, anti-references, tokens, an anatomy table and six states.
- Evidence: v2 `references/design-quality.md:60-134` (interdits then gate checklist), `templates/screen.md.tmpl:23-162` — `## 4. États` lists 9 states including "Vide — jamais visité", "Erreur de soumission", "Lecture seule"; `## 8. Données` asks origin, required, error; `## 9. Traçabilité` maps each B/E/C ID to where it is visible. v3 `skills/forge-design/references/screen-template.md:1-27` has Purpose, Anatomy, States (six, no trigger/render/feedback columns), Interactions, Responsive, Accessibility; no data section, no per-ID traceability, no per-screen visual direction.
- Impact: the design deliverable loses the two sections that make an AI-written screen implementable — where the data comes from and which requirement each zone satisfies. The "anti-generic" corpus was the project's answer to the failure mode it names (white, generic, soft) and is not replaced by mood words.
- Recommendation: restore the sections in `screen-template.md` and add "traceability" and "data" to `forge.HEADINGS["screen"]` so the registration check enforces them; re-add the interdits as a checklist under `skills/forge-design/references/review-checklist.md` (F4) with the three mechanically detectable ones (pure-white background, default palette hexes, body text under 16px on mobile) enforced by the `tokens` check of F5.

### F7 — Scenario tests and test-strategy selection were dropped
- Ref: matrix 12, 13
- Status: verified
- Severity: major
- What: v2 had a dedicated reference on business-scenario tests (a sequence of business events producing a correct, durable state), a dedicated agent to write them, and a strategy reference for choosing among seven test families. v3 has one line in the test-plan template.
- Evidence: v2 `references/scenario-tests.md:3-18` (what a scenario proves that a unit test does not), `:20-51` (two non-negotiable rules: a scenario never writes what the app writes; a temporal domain needs a simulated clock), `:71-85` (the final invariant is the part most often missing), `agents/scenario-tester.md:1-56`; `references/test-strategies.md:20-113` plus its measured pitfalls (`:99`) and per-stack table (`:82`). v3 `skills/forge-plan/references/test-plan-template.md:5`: "Unit, integration, end to end, and interface checks: what each level covers and the tool used." `agents/` has no scenario role (9 agents, none named for tests).
- Impact: a plan can satisfy `P4` (`skills/forge-plan/SKILL.md:26`, one `TC-` line per plan) with unit tests only; nothing asks for a lifecycle test, a fixed clock or a final invariant. The v2 rule about a test writing the state it verifies is the one that catches a false green in generated test suites, and it has no successor.
- Recommendation: add `scenario` and `clock` rows to the test-plan template with a CLI check that at least one row per release is a scenario, and restore the "never write what the app writes" rule as a `forge-qa` question in the plans checklist (F4).

### F8 — The data model is prose again: DDL is neither written nor executed
- Ref: matrix 15
- Status: verified
- Severity: major
- What: v2's rule was "the DDL executes, or it is not written": SQL blocks in `architecture.md` were extracted, executed against an embedded PostgreSQL, and the declared guards were tested. v3's architecture template asks for "Entities, fields with types, relations, indexes" and no SQL.
- Evidence: v2 `SKILL.md:782-819` and `scripts/ddl-exec.js:478-577` (`PGlite`, `ddl_executes`, `skipped` when the engine is absent rather than a false green). v3 `skills/forge-architect/references/architecture-template.md` §5; `cli/forge.py` has no SQL, DDL or schema term; `skills/forge-rules/references/templates/domain/data-and-state.md` discusses data rules, not a schema.
- Impact: a data model with a missing unique constraint, a missing foreign key or a wrong type passes architecture, plans and build. `docs/STATUS.md` nowhere records the removal, and the v2 reason (a DDL that never ran is a guess) still holds.
- Recommendation: either restore an executable DDL block in the architecture template with the optional-engine `skipped` semantics, or record in `docs/MIGRATION-v2.md` that execution is removed on purpose and why. Leaving the template silent is the one option that hides the loss.

### F9 — Nothing detects a dependency cycle between slices
- Ref: matrix 16
- Status: verified
- Severity: major
- What: v2 computed cycles and a topological order from declared dependencies. v3 asks the architect to write the dependency graph and never reads it.
- Evidence: v2 `scripts/dependency-check.js:116-155` (`findCycles`, `topologicalOrder`), `SKILL.md:757-776`; `state.js:2284` (`dep`). v3 `skills/forge-architect/SKILL.md:23` requires "the dependency graph between slices"; `cli/forge.py:766-795` parses `slices.md` for id/name/module/serves only and `coverage_problems` never reads a dependency. `slices-format.md` has no dependency column.
- Impact: two slices can require each other and the build order in `plans/index.md` becomes unsatisfiable, discovered only at implementation time. The plan gate (`cli/forge.py:813-845`) cannot see it.
- Recommendation: add a `depends` column to `slices-format.md`, parse it in `parse_slices`, and run the v2 cycle check in `forge check coverage`; add a two-slice cycle mutation to `tests/flow.sh`.

### F10 — Cross-artifact consistency collapsed to ID coverage
- Ref: matrix 17, 11
- Status: verified
- Severity: major
- What: v2 verified, across artifacts: every screen reaches a slice, every navigation entry reaches a screen, every cited ID resolves, every `§section` reference resolves, the plan matches the architecture it quotes, and the phase journal matches the state. v3 verifies requirement IDs against slices and deliverables against withdrawn premises.
- Evidence: v2 `scripts/consistency-check.js:307-368` (`screens_have_slices`, `nav_items_have_screens`), `:119` (`checkSliceReality`), `:1062` (`checkCitationAccuracy`), `:1267` (`checkSectionReferences`), `:894` (`checkStateParity`) — 1512 lines total. v3 `cli/forge.py:778-845`: `coverage_problems`, `premises_problems`, `plans_problems`. A screen's `serves:` header (`skills/forge-design/references/screen-template.md:5`) is never read by the CLI, and `skills/forge-design/SKILL.md:13` says a tab or a state is not a screen but nothing checks it.
- Impact: a screen can serve no requirement, a navigation entry can lead nowhere, a plan can quote an API contract that the architecture does not define, and the design gate still passes. The roadmap and PRD links are covered; the design→architecture→plans links are not.
- Recommendation: extend `design_problems` with the two v2 checks (`screen.serves` ⊆ live PRD IDs; every screen in `screen-map` appears in at least one slice's `serves` or a foundation `region`), with mutations in `tests/design.sh` and `tests/flow.sh`.

### F11 — `slice done` now checks the shape of a sentence
- Ref: matrix 18
- Status: verified
- Severity: major
- What: v2 executed the project's own commands per slice and counted real test cases in the test files, because "le test existe" alone had let 14 slices be approved with zero test cases. v3 matches the evidence string against `^.{3,}\s:\s.{3,}$`.
- Evidence: v2 `scripts/forge-exit.js:1-23`, whose header states the measured failure at `:15-16` ("sur un projet réel, 14 slices ont été approuvées sans aucun cas de test"); `consistency-check.js:103` (`countTestCases`). v3 `cli/forge.py:881-884` (regex, then `s["slices"][id] = "done"`, journal the evidence). `tests/flow.sh:67` passes with `--evidence "pytest tests/test_pay.py : 4 passed"` and no test file exists.
- Impact: the CLI cannot distinguish a real test run from a plausible sentence, and the build gate (`cli/forge.py:478-483`) accepts the sentence. This is v2's own most expensive lesson, unrecorded.
- Recommendation: have `forge slice done` run the commands named in the project's `quality-gates.md` read-only, or accept a `--report <file>` containing the command output, and require at least one test case per plan ID. A cheaper intermediate: make the evidence name a command that `tests/` or the project gate config declares.

### F12 — The audit-from-own-runs loop lost its taxonomy, its aggregation and its promotion step
- Ref: matrix 19
- Status: verified
- Severity: major
- What: v2 journaled a closed set of incident types, required an `origin` field (`forge` / `projet` / `environnement`), kept aggregate metrics, aggregated journals across projects to separate structural from one-off failures, and routed each finding to a promotion domain so it could become a rule. v3 keeps an append-only journal and free-text `forge memory log`.
- Evidence: v2 `SKILL.md:1101-1145` (files, mandatory types, "L'onglet `origine` … est le champ le plus important", `audit-report.js:427` exits 2 on a structural problem), `state.js:2312` (`finding`), `agents/scenario-tester.md:36-38` (`--domain=`), `SKILL.md:1178-1180` (rules 13-14: a finding with no promotion domain changes nothing). v3 `skills/forge-memory/SKILL.md:10-15` (journal + `forge memory log`), `cli/forge.py:173-177` (`journal`), no `origin`, no metrics, no aggregation. `grep -r "promot\|origin\|metric"` over `cli/`, `docs/`, `skills/`, `agents/` returns nothing on this topic.
- Impact: `lessons.md` accumulates but nothing turns a lesson into a rule, which is the mechanism that produced the v2 corpus in F19. Worse, `skills/forge-memory/SKILL.md:44` claims trigger 11 ("A gate or review fails") is an "automatic journal entry", and `cmd_gate` journals approvals only (`cli/forge.py:546`); `AGENTS.md:180-181` records the discrepancy. A failed gate is therefore invisible in the very file the audit loop reads.
- Recommendation: journal refusals in `cmd_gate` and in `die()`-level refusals with a type and an origin, add `forge audit report <dir>` porting `audit-report.js`, and add one field to `forge memory learn` for the promotion target. Fix the `forge-memory` line or the code in the same change (`AGENTS.md:23-32`).

### F13 — The product interview protocol is one line
- Ref: matrix 20
- Status: verified
- Severity: major
- What: v2's `product-analyst` carried a full interviewer contract: eight categories in order, one or two questions at a time, no leading questions, probes for vague answers, four implications to always ask about (error, empty state, permission, consequence), five alarm signals, and a closing summary to confirm. v3's phase skill says "Interview the user."
- Evidence: v2 `agents/product-analyst.md:28-101`. v3 `skills/forge-discover/SKILL.md:30`; `agents/forge-analyst.md:1-17` lists six steps, none about asking. The PRD template (`skills/forge-discover/references/prd-template.md`) has one section per answer, which presupposes the answers exist.
- Impact: the PRD is the deliverable everything downstream cites (`B/E/V/C` ids), and its quality now depends on a single instruction. v2's own alarm signals ("tout le monde sait que…", "simple à utiliser" + 15 features) target exactly the answers a weaker model accepts. The client mode ("ask in business terms and batch the questions") does not replace them.
- Recommendation: move the v2 interview section into `skills/forge-discover/references/interview.md` (one reference file per phase skill, as the other phases do) and point `forge-discover` step 1 at it; keep the v2 eight categories and the four implication probes verbatim.

### F14 — "Challenge mode" is invoked on an agent that does not define it
- Ref: matrix 21
- Status: verified
- Severity: major
- What: v2 had a dedicated `premise-challenger` agent that reads the user's premises rather than Forge's documents, with an attack grid and a rule that one `critical` verdict blocks until the user answers. v3 tells the orchestrator to launch `forge-redteam` "in challenge mode", and `forge-redteam.md` has no such mode.
- Evidence: v2 `agents/premise-challenger.md:36-118`; `skills/forge/SKILL.md:1070` (one critical blocks). v3 `skills/forge-discover/SKILL.md:16`; `agents/forge-redteam.md:1-6` ("Finds contradictions, wrong assumptions and risks") and `:14-18` (five steps on "the deliverable" and "earlier deliverables"). No file in `agents/` or `skills/` contains the word "challenge" outside that one line (`grep -rn challenge` matches only `skills/forge-discover/SKILL.md:16`).
- Impact: an agent with no mandate to question the idea is told to question the idea, and its own contract tells it to review documents. The premise challenge is the one step that can stop a wrong product before the PRD; it now runs as a normal review of nothing, and its output is recorded in the landscape document rather than blocking.
- Recommendation: either restore a `forge-redteam --mode challenge` contract section (inputs = the user's words only, output = questions, one `critical` blocks) or add the section to `agents/forge-redteam.md` and a `tests/` case showing the block. `AGENTS.md:23-32` forbids letting the skill and the agent disagree.

### F15 — The archetype catalogue and its measured pathologies are gone
- Ref: matrix 22
- Status: verified
- Severity: major
- What: v2 carried eight application archetypes with the standards expected of each, the recurring pathologies measured per archetype (money and due dates for rental/tenancy, cross-archetype list), and a comparison grid used by the `plan-validator` agent. v3 keeps the instruction to name an archetype and nine starting orders for screen anatomy.
- Evidence: v2 `references/archetypes.md:35-241` (É1 to É8, `:187-225` pathologies, `:226` comparison grid), consumed by `agents/premise-challenger.md:15` and the Fast Track `plan-validator`. v3 `skills/forge-discover/SKILL.md:17`; `skills/forge-design/references/hierarchy.md:16-27` (nine patterns, screen-level only).
- Impact: "is this plan normal for this kind of application?" was answerable from a file; it is now a `forge-qa` judgement. The pathologies section is the part that came from real projects and cannot be re-derived by a model.
- Recommendation: move `archetypes.md` (minus the Fast Track wiring) into `skills/forge-discover/references/` or `skills/forge-design/references/`, and add one question per archetype to the checklist of F4.

### F16 — The self-tests that verified the kit's own claims are gone
- Ref: matrix 3
- Status: verified
- Severity: major
- What: v2's `selftest.js` asserted that the seven references exist, the nine templates exist, the eight agents exist and each declares an exploitable contract, the scripts parse and require the shared library, every status belongs to the vocabulary, and the design agent imposes navigation prioritization and design quality. v3's 14 suites test the CLI's behaviour; none tests what the skills and agents claim about themselves.
- Evidence: v2 `selftest.js` (5679 lines; `test('les 7 références existent')`, `test('les 8 agents existent')`, `test('chaque agent déclare un contrat exploitable')`, `test('ux-designer impose la priorisation de navigation et la qualité de design')`), `skills/project-rules-architect/scripts/selftest.js` (286 lines). v3 `tests/` greps: only `tests/install.sh:17-48` asserts that named installed files exist, and `tests/templates.sh:8-20` asserts template headings. No suite reads `skills/*/SKILL.md` or `agents/*.md`.
- Impact: this is how F13, F14 and F15 survive: the contracts those v2 tests asserted are exactly the ones v3 dropped. A skill can lose a requirement and no suite notices; a v3 test weaker than its v2 counterpart is invisible (`AGENTS.md:43-44`).
- Recommendation: port the meta-tests as `tests/kit.sh`: every reference file cited by a SKILL.md exists, every agent named by a skill exists, every phase skill names its producer and reviewers, every `forge <command>` in a skill exists in `cli/forge.py` (the `hints_point_to_real_commands` check of F1 in shell form).

### F17 — Version, changelog and a reproducible release artifact are gone
- Ref: matrix 5, 6, 43
- Status: verified
- Severity: major
- What: v2 had one `VERSION` for the repository, a 2496-line `CHANGELOG.md` in Keep-a-Changelog form, `release.js bump|check`, a deterministic `snapshot.js build|verify`, smoke tests for both, and a changelog policy that stopped a PR from editing published sections. v3 has no version anywhere: not in `VERSION`, not in the CLI (`cli/forge.py:7` is `VERSION = 3`, the schema, not the release), not in `install-manifest.json`.
- Evidence: v2 `scripts/release.js:1-25`, `scripts/snapshot.js:1-40` (deterministic archive, "une release qui ne permet pas de retrouver ce qu'elle a publié n'est pas une release"), `VERSION:1`, `CHANGELOG.md:1-20`, `scripts/changelog-policy.js:1-25`, `ci.yml:29-56`. v3: `git ls-files` has no `VERSION`, `CHANGELOG.md`, `package.json` or `LICENSE`; `scripts/install.py:213` writes `{scope, targets, settings_created, ...}` with no version; `forge kit verify` compares hashes of installed copies (`cli/forge.py:1233-1270`) but cannot say *which* version they are.
- Impact: a user cannot answer "which Forge am I running?", a bug report cannot be tied to a release, and there is no artifact to compare a local kit against. The README installs from `main` (`README.md:21-22`), so two installs a week apart are silently different with no changelog entry. This is a distribution capability, not comfort: the installer replaced the artifact, but it records no identity.
- Recommendation: add a version string to `cli/forge.py`, print it in `forge status` and in `install-manifest.json`, and create `CHANGELOG.md` with one entry per v3 change. The snapshot tooling can stay out until there is a release process; the identity cannot wait, because `forge kit verify` is only meaningful relative to a named version.

### F18 — The stray-character scan and its allow-list lesson were dropped
- Ref: matrix 23
- Status: verified
- Severity: major
- What: v2 scanned the kit's own sources for characters outside a documented allow-list (ASCII + Latin-1 + Latin Extended-A + punctuation + the repository language's typography), with an `unicode-scan:ignore` escape for quoting a defect. v3 has no such scan.
- Evidence: v2 `SKILL.md:1223-1252` records both failures it was built from: a PowerShell regex that reported 0 problems on corrupted files, and a Node replacement that passed a file containing `U+1EE1` because it assumed CJK corruption. The check is `validate-repo.js:520` (`no_stray_characters_in_skill_source`). v3: `cli/forge.py:1528-1546` (`lint-rules`) checks banned wording only; no suite reads bytes of skill sources.
- Impact: v3 ships Markdown to 2 agent runtimes and a rule template library to arbitrary projects; a mojibake sequence in a template is copied into every generated rule set. This audit's own reads of the baseline return U+FFFD and substituted Latin Extended-A letters throughout `skills/forge/SKILL.md`, which is why the allow-list existed. Without the scan, v3 has no way to know whether its own files are clean, and the whitelist-not-blacklist lesson (the third parasite was found only by an allow-list) is unrecoverable from the v3 tree.
- Recommendation: port the allow-list scan into the F1 validator, with the language list driven by the files being scanned (the repository ships English now, so Latin Extended-A is not needed), plus one mutation: insert `U+1EE1` into a reference file and assert the check names the file and line.

### F19 — The 14 verification rules that came from 43 real corrections are not in v3
- Ref: matrix 24
- Status: verified
- Severity: major
- What: v2's `SKILL.md` carried a numbered corpus of 14 verification rules distilled from 43 corrections on a real project, all of which it says were verification errors rather than knowledge errors. No v3 file contains them.
- Evidence: v2 `SKILL.md:1146-1180`; representative rules: "Un code de sortie n'est pas un résultat" (2), "Un contrôle qui vérifie la PRÉSENCE d'un changement ne peut pas vérifier son CONTENU" (3), "Un test qui réimplémente la règle qu'il est censé tester ne teste pas la règle" (5), "Un attendu est un énoncé, pas une invention" (8), "Un fait, deux représentations" (10), "Une frontière sans deux tests n'est pas une frontière" (11). v3: `grep` over `skills/`, `agents/`, `AGENTS.md`, `docs/` for these formulations returns nothing; the closest v3 prose is `AGENTS.md:133-149` (quality bar, PRD rules), which is about the kit, not about how to verify a claim.
- Impact: these rules are the only part of v2 that transferred lessons from project work into the agent's behaviour. v3 keeps their *conclusions* in places (hash-bound reviews, mutation suites) but not the rules themselves, so a new check added to `cli/forge.py` has no stated obligation to be seen failing. `AGENTS.md:39-44` restates two of them for the kit; the project-facing skills do not.
- Recommendation: add `skills/forge/references/verification.md` with the 14 rules, and point R11 and the `forge-build`/`forge-qa` contracts at it. Pair it with a rule in `AGENTS.md` that a new CLI check ships with a mutation, which is I4 stated for the checkers rather than for the shortcuts.

### F20 — Three smaller mechanisms lost their record
- Ref: matrix 25, 26, 27
- Status: verified
- Severity: minor
- What: (a) v2's module-prioritization procedure (frequency × centrality, five steps, worked example) and its `state.js set-nav` record are reduced to hierarchy rule H4 and a design-system heading; (b) v2's research protocol (six questions, the shape of a warning, anti-goals, output control) is reduced to a six-section landscape template; (c) v2's amendment protocol (extend, never renumber, record `amendedBy`) is reduced to a PRD ID check, with slice IDs unchecked.
- Evidence: v2 `references/module-prioritization.md:13-127` + `state.js:2309`; v3 `skills/forge-design/references/hierarchy.md:9` + `skills/forge-architect/SKILL.md:22`, no CLI record of the order. v2 `references/research-protocol.md:15-113`; v3 `skills/forge-discover/references/landscape-template.md:1-23` (invariants and decisions kept, discipline lost). v2 `state.js:2285`, `SKILL.md:450-486`; v3 `cli/forge.py:738-751` checks PRD IDs only, `cli/forge.py:766-775` never parses the `## Removed` section that `slices-format.md` mandates.
- Impact: navigation order can no longer be justified or checked; research can be padded without tripping the v2 anti-goals; a removed slice ID can be reused, and the `## Removed` rule is a format the CLI does not read — the same defect `AGENTS.md:140-143` calls out for templates (a section the CLI does not check).
- Recommendation: either parse `## Removed` in `parse_slices` and refuse a reused ID, or drop the rule from `slices-format.md`. For the other two, record the intent in `docs/MIGRATION-v2.md` (deliberate simplification) rather than leave them undecided.

## Regressions with no record

`docs/MIGRATION-v2.md` is 33 lines. It names the entry file, state changes, the state file, phases, Fast Track, agents, review, memory, compliance, client touchpoints, the rules generator and the absence of automatic migration (`:7-17`, `:21`). None of the rows below is covered by any of those lines.

| Capability lost | Closest migration line | Why the line does not cover it |
|---|---|---|
| Repository-wide validator (F1) | `:7` (entry file) | speaks of the skill file split, not of validating references |
| CI (F2) | none | no line mentions tests, CI or enforcement of the repository |
| Self-tests of the kit's claims (F16) | `:13` (review) | speaks of review reports, not of tests over skills and agents |
| Impact protocol (F3) | `:10` (phases) | lists phase order only |
| Per-document checklists (F4) | `:13` (review) | says reviews are hash-bound, not which questions they ask |
| Design measurement, quality rules, screen depth (F5, F6) | `:10` (phases) | moves visual references into design; says nothing about measurement |
| Scenario tests and test strategies (F7) | none | no line mentions testing at the project level |
| Executed DDL (F8) | none | the word database does not appear |
| Dependency cycles (F9) | none | no line mentions dependencies |
| Cross-artifact consistency (F10) | none | no line mentions consistency between deliverables |
| Slice exit criteria (F11) | `:12` (agents) | speaks of agent count and review wiring |
| Audit loop (F12) | `:14` (memory) | replaces the memory layout, not the incident taxonomy or aggregation |
| Interview protocol (F13) | `:12` (agents) | counts agents; does not say `product-analyst` lost its interview |
| Premise challenger (F14) | `:11`, `:12` | Fast Track removal covers `plan-validator`; `premise-challenger` is never named |
| Archetypes and pathologies (F15) | `:11` (Fast Track) | the archetype file outlived Fast Track and had other consumers |
| Release, version, changelog (F17) | none | no line mentions versioning or distribution |
| Stray-character scan (F18) | none | no line mentions source hygiene |
| Verification discipline (F19) | none | no line mentions the 14 rules |
| Module prioritization, research protocol, amendment (F20) | `:10`, `:9` | adjacent in topic, not stated |

## Rejected candidates

Capabilities that look lost and are intentionally superseded, with the reason and the
citation that carries it.

| Candidate | Why it is not a regression | Citation |
|---|---|---|
| Fast Track (automatic phases 4-5, two autonomy levels) | Removed on purpose: client mode replaces it and keeps every gate; the 3-attempt guard becomes the general loop guard | `docs/MIGRATION-v2.md:11`; `cli/forge.py:27-29`; `tests/loops.sh:1` |
| `plan-validator` agent | Its only consumer was Fast Track; archetype conformance now belongs to `forge-qa`/`forge-redteam`. The catalogue it read is still a loss (F15) | `docs/MIGRATION-v2.md:11-12` |
| `references/skill-boundaries.md` (Forge ↔ project-rules-architect) | One owner now: the rules generator is a Forge phase, so a boundary contract has no counterparty | `docs/MIGRATION-v2.md:17`; `skills/forge-rules/SKILL.md:1-5` |
| `state.json` v2 schema and the front-matter mirror (`state.js sync`) | Removed on purpose: one status per item, sealed, written by the CLI only | `docs/MIGRATION-v2.md:9`; `cli/forge.py:66-86` |
| `.forge/tools/` declared helper scripts (`forge-guard.js tools`) | v3 has no project-side scripts: the CLI is the only writer of state, and skills tell agents never to edit `.forge/state.json` | `skills/forge/SKILL.md:19` (R2); `agents/forge-analyst.md:12` |
| Guided multi-perspective rotation (two postures in one session) | Superseded by two independent agents on a hash, which is strictly stronger and cannot self-certify | `docs/MIGRATION-v2.md:13`; `tests/adversarial.sh:44-49` |
| `migration-v1-v2.md` (state.json migration) | No automatic migration on purpose; the new procedure is documented | `docs/MIGRATION-v2.md:19-27` |
| v2 memory layout (`context`, `session-log`, `DECISIONS`, `LEARNINGS`) | Replaced by `NOW.md`, journal, decisions, lessons, with hooks for compaction | `docs/MIGRATION-v2.md:14`; `skills/forge-memory/SKILL.md:10-15` |

## Open questions

1. **Was dropping CI a decision?** `AGENTS.md:45-47` states the absence as a fact; no line in `docs/MIGRATION-v2.md` or `docs/IMPROVEMENTS.md` records a decision. If the intent was "POSIX-only suites, no CI runner", the record should say so; otherwise F2 is an accident. (inferred)
2. **Is v3 still meant to be installable by `npx skills add`?** `docs/STATUS.md:39` says the standard layout is followed but "not yet tested with the tool", and v2's `validate-repo.js` is what enforced that conformance. Either the route is supported (then F1's portable-id and strict-YAML checks are required) or it is dropped (then the README and `docs/MIGRATION-v2.md` should say so). (inferred)
3. **Does `forge kit verify` need a version?** Today it proves "nothing changed since install" (`cli/forge.py:1233-1270`) but not "which Forge this is". Should the manifest carry the release identity (F17)? (verified gap, open decision)
4. **Is `LICENSE` deliberately absent?** v2 had `LICENSE` and `"license": "MIT"` in `package.json:5`; v3 has neither. Not a capability, so not scored, but a distribution question for the owner. (verified)
5. **Who runs the 14 suites?** With no CI and no git hook, the only enforcement is `AGENTS.md`. Is a `pre-commit` hook (or `forge verify`) the intended answer, or is the omission part of F2's decision? (inferred)
6. **`AGENTS.md:180-181` says `forge-memory` claims a failed gate is journaled and `cmd_gate` journals approvals only.** Confirmed by `cli/forge.py:546`; left unresolved here because it is a v3-internal defect rather than a v2 parity item, but it is the observable symptom of F12. (verified)
7. **Was `premise-challenger` folded into `forge-redteam` on purpose?** `docs/MIGRATION-v2.md:12` counts agents 11 → 8 without naming which survived; the v3 skill invokes a "challenge mode" that no agent file defines (F14). (verified absence, open intent)
