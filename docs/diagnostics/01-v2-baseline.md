# v2 baseline: production method and deliverable requirements

## Scope and method

**Subject.** The v2 baseline is `tleguede-works/ship-clean-skills`, cloned read-only at
`C:\Users\Thibaut LEGUEDE\AppData\Local\Temp\opencode\v2-baseline`. `VERSION` = `1.14.0`,
`git rev-list --count HEAD` = `1` (single-commit clone, so no history is available), `git status`
clean. Every citation below is a path relative to that clone root, plus a line number.

**What was read.** In full: `skills/forge/SKILL.md` (1289 lines, 84 385 bytes);
the 11 files under `skills/forge/agents/`; the 12 files under `skills/forge/references/`;
the 12 `skills/forge/templates/*.tmpl`; `skills/forge/README.md`; `.github/workflows/ci.yml`.
Consulted at the cited regions: `scripts/validate-repo.js`, `skills/forge/scripts/state.js`,
`skills/forge/scripts/design-check.js`. File sizes were measured with
`Get-Item`/`Measure-Object`, not quoted:
`agents/` = 81 440 bytes, `references/` = 116 066, `templates/` = 74 834,
`scripts/` = 787 401 of which `state.js` alone is 103 613.

**Status vocabulary.** `verified` = the cited text was read at the cited line, or the cited
command's output was observed. `inferred` = a conclusion drawn from two or more verified
statements, with the reasoning stated. `hypothesis` = plausible, not testable from this clone.

**Severity vocabulary.** `critical` = breaks the workflow or lets a phase be skipped.
`major` = degrades deliverable quality. `minor` = drift.

**Counting conventions.** "Declared" counts come from the text that claims them; "actual" counts
come from `Get-ChildItem -File`. Byte sizes are file lengths. Corruption counts are
case-insensitive substring counts over `skills/forge/**`, not deduplicated.

**Coverage limits.** No v2 script was executed: the clone carries no `node_modules`, and the
audit is read-only by instruction. No v2-managed project (a `.forge/` produced by v2) exists in
the clone, so every claim about what v2 projects *actually contain* is `hypothesis` and is
listed in Open questions. Every phase-table row is `verified`; a cell whose mechanism is a
deduction carries `(inferred)` in that cell.

**Fact correction.** A briefing supplied with this audit gave "1289 total / 904 non-empty" lines
for `SKILL.md` and 8 agents / 9 templates / 7 references / 6 scripts. The line count is right;
the file counts are the v2 README's claims, not the disk. Actual: 11 agents, 12 templates,
12 references, 10 scripts + `lib/forge-lib.js` (see W24).

---

## Phase-by-phase requirements

### Phase 0 — Bootstrap

Heading at `skills/forge/SKILL.md:325`. Purpose: establish project context and the conventions
base before any product reflection (`skills/forge/SKILL.md:327`).

| Requirement | Where | Mechanism that forces depth |
|---|---|---|
| Resolve the anchor before anything else | `skills/forge/SKILL.md:329` | `state.js anchor` refuses a reference project as anchor (`skills/forge/references/state-schema.md:255`) |
| Read existing configuration when the project exists | `skills/forge/SKILL.md:330` | Five named sources (`package.json`, `tsconfig.json`, `.opencode/`, `AGENTS.md`, rules, ADR) and the instruction to extract *implicit* conventions, not restate the files |
| Interview the stack when the project is greenfield | `skills/forge/SKILL.md:331`–`334` | Three closed questions (stack, hosting constraints, mandatory or excluded tools) |
| Create `.forge/` through the CLI | `skills/forge/SKILL.md:335` | `state.js init` creates `state.json` v2; a v1 state is refused, not migrated silently (`skills/forge/references/state-schema.md:236`) |
| Call 1 to `project-rules-architect`, scaffold mode only | `skills/forge/SKILL.md:336`, `377`–`386` | "A return that contains rules is a bad return" (`skills/forge/SKILL.md:386`); the call is dated and later gated by `rules-present` (`skills/forge/SKILL.md:410`–`415`) |
| Generate `conventions.md` from the template, undecided sections marked `À DÉCIDER EN PHASE 4` | `skills/forge/SKILL.md:337`; `skills/forge/templates/conventions.md.tmpl:16`–`188` | The marker makes an unfinished section visible; a silently empty section is the failure it prevents |
| Register the deliverable | `skills/forge/SKILL.md:338` | `state.js register` validates the path against `CANONICAL_LAYOUT` (`skills/forge/references/state-schema.md:199`–`211`) |
| Generate `contract.md`, run `client-liaison --check`, then have it signed | `skills/forge/SKILL.md:339`–`343` | Five numbered sections plus two closing ones, including §3 "irreversible" (`skills/forge/templates/contract.md.tmpl:51`) and §4 "what Forge will decide alone" (`:71`) |
| After signature, only two interruption reasons | `skills/forge/SKILL.md:348`–`362` | Four mandatory fields per client point (`what`, `price`, `by`, `if_no_answer`); a missing one is refused, an expired date makes Forge decide (`:359`–`362`) |
| Summarize detection and ask for confirmation | `skills/forge/SKILL.md:344` | Gate is human by principle #2 (`skills/forge/SKILL.md:35`), enforced by `PHASE_ARTIFACT_OWNERS` (`:36`) |

**Required output.** `.forge/conventions.md`, `.forge/contract.md` (status `approved`), the four
memory files at the anchor root (`AGENTS.md`, `SESSION_LOG.md`, `DECISIONS.md`, `LEARNINGS.md`),
`.forge/state.json`.

**Gate.** `forge-guard contract` refuses a contract that leaves a purchasing decision unsigned
(`skills/forge/SKILL.md:351`). No Phase 0 row exists in the normative per-phase table
(`skills/forge/SKILL.md:300`–`307`) — see W20.

### Phase 1 — Discovery (PRD)

Heading at `skills/forge/SKILL.md:487`. Explicitly not a writing phase: "an interview and
maturation phase" (`:491`).

| Requirement | Where | Mechanism that forces depth |
|---|---|---|
| Cover eight interview categories, in order | `skills/forge/SKILL.md:495`–`506` | "One or two questions at a time, do not bombard the user" (`:497`) — cadence is a rule, not a style note |
| Challenge the answers with seven named moves | `skills/forge/SKILL.md:508`–`518` | Each move ships an example sentence (contradiction, implicit, limits, ambition, omission, dependency, alternative) |
| Run `premise-challenger` twice in this phase | `skills/forge/SKILL.md:493`; `skills/forge/agents/premise-challenger.md:40`–`41` | One `critical` verdict blocks until the user answers (`skills/forge/SKILL.md:1070`); the user's decision still wins (`skills/forge/agents/premise-challenger.md:143`) |
| Write to `.forge/prd.md` only, from the template | `skills/forge/SKILL.md:522`; `skills/forge/templates/prd.md.tmpl:18`–`183` | 12 sections; "never in `state.json`, never elsewhere" |
| Give every business rule, edge case and constraint a stable ID | `skills/forge/SKILL.md:525`–`528`; `skills/forge/templates/prd.md.tmpl:65`–`93` | IDs are final and never reused; a removal keeps its ID and its reason (`skills/forge/templates/prd.md.tmpl:131`–`157`) |
| Keep implementation jargon out of the PRD | `skills/forge/SKILL.md:530` | A gate item, not advice (`skills/forge/references/review-checklists.md:17`) |
| Register, then `forge-guard placeholders`, then the gate | `skills/forge/SKILL.md:533` | Ordering is explicit: a residual `{{PLACEHOLDER}}` is caught before the human reads the document |
| Rotate posture (quality, then risk) before the gate | `skills/forge/SKILL.md:535`–`541`, `1011`–`1018` | Mandatory for the PRD (`:1018`); each posture carries three questions to answer |
| Research: archetype, at least two reference products **read**, invariants not code, archetype §9 pathologies, assumed gaps with reversibility cost | `skills/forge/SKILL.md:543`–`553` | "A research that changes no decision produced nothing" (`:553`); anti-objective table forbids 20 products, copying an architecture, writing research into `state.json` (`skills/forge/references/research-protocol.md:89`–`98`) |
| Gate | `skills/forge/SKILL.md:555`–`557` | `references/review-checklists.md#prd` — dangling, see W1 |

**Required output.** `.forge/prd.md` (12 sections, IDs B/E/C), `.forge/benchmarks.md`
(written here per `skills/forge/SKILL.md:548` — but see W3).

**Gate.** `forge-guard placeholders`, `client-liaison --check` (`skills/forge/SKILL.md:302`) —
the second one is issued by an agent whose declared phases exclude 1 (W5).

### Phase 2 — Scope (Roadmap)

Heading at `skills/forge/SKILL.md:559`. Purpose: decide what enters each version and why
(`:561`).

| Requirement | Where | Mechanism that forces depth |
|---|---|---|
| Score every feature on value, complexity, dependencies, risk | `skills/forge/SKILL.md:565`–`566` | Four axes, not a priority list |
| Define MVP as the smallest set usable by real users, then V1, then defer to V2+ | `skills/forge/SKILL.md:567`–`569` | Three-way split with an explicit deferral bucket |
| Justify each version: included, deferred, trade-offs, risks | `skills/forge/SKILL.md:571`–`577` | Four questions per version, each answered in the template (`skills/forge/templates/roadmap.md.tmpl:94`) |
| Write `.forge/roadmap.md` from the template | `skills/forge/SKILL.md:581`; `skills/forge/templates/roadmap.md.tmpl:18`–`123` | 7 sections; §2.2 "what is NOT in the MVP" is a required section, not an omission |
| Per version: feature IDs, success criteria, inter-version dependencies, relative effort, risks | `skills/forge/SKILL.md:583`–`588` | Effort is relative by rule ("not in days"), which blocks false precision |
| Rotate posture before the gate | `skills/forge/SKILL.md:590`–`594` | Two questions aimed at the MVP's sufficiency, not its contents |
| Gate | `skills/forge/SKILL.md:596`–`598` | `references/review-checklists.md#roadmap` — dangling, W1 |

**Required output.** `.forge/roadmap.md` (7 sections).

**Gate.** `consistency-check premises` (`skills/forge/SKILL.md:303`), which compares the
`premises` list against the real PRD and reports a withdrawn requirement that an approved
deliverable still depends on (`skills/forge/SKILL.md:266`).

### Phase 3 — Design (UI/UX)

Heading at `skills/forge/SKILL.md:600`. "The order of this phase is structural. Do not shortcut
it." (`:604`)

| Requirement | Where | Mechanism that forces depth |
|---|---|---|
| Establish direction **before** any screen | `skills/forge/SKILL.md:606`–`613` | "Nothing is drawn before these two documents" (`:608`) |
| Store the archetype and the work loop (one sentence) in `state.json` | `skills/forge/SKILL.md:610` | `product.archetype` is state, so it is machine-readable afterwards |
| Call a design skill, or justify its absence in the audit | `skills/forge/SKILL.md:611`; `skills/forge/references/design-quality.md:36`–`58` | Absence must be recorded, which makes skipping it visible |
| Fix the three anchors: references, mood (three words), anti-references | `skills/forge/SKILL.md:612` | "Without them, Phase 3 is not finished" |
| Generate `.forge/benchmarks.md`: reference products, archetype conformance grid, assumed gaps | `skills/forge/SKILL.md:613`; `skills/forge/templates/benchmarks.md.tmpl:24`–`104` | 7 sections; §5 records each gap with its reversibility cost (`:81`) |
| Rank navigation by frequency × centrality, cap at 5 items, "Home" not first by default | `skills/forge/SKILL.md:615`–`623`; `skills/forge/references/module-prioritization.md:36` | Two 1–5 scores plus a one-sentence justification per entry; order is written via `state.js set-nav` (`skills/forge/SKILL.md:628`) |
| Design tokens with concrete values, primitives, navigation patterns, the four prohibitions | `skills/forge/SKILL.md:631`–`637`; `skills/forge/templates/design-system.md.tmpl:15`–`308` | "Never 'to be defined later'" (`:633`); §0.0 colour-class declaration (`skills/forge/templates/design-system.md.tmpl:15`) |
| Measure contrast, do not write it | `skills/forge/SKILL.md:638`–`684` | `design-check contrast`; the `forge:token-classes` block declares text/on/surface/nontext/exempt; the recorded failure is a French-named palette where every token fell into "non-textual" and a 3.80:1 text passed (`:643`–`650`) |
| One file per screen, 9 states, per-screen direction, interactions, responsive at each breakpoint, accessibility, traceability | `skills/forge/SKILL.md:686`–`693`; `skills/forge/templates/screen.md.tmpl:16`–`162` | "A residual `{{PLACEHOLDER}}` is a state that will not be implemented" (`:692`); the 9 states are enumerated once (`skills/forge/references/review-checklists.md:84`) |
| Component parity across screens | `skills/forge/SKILL.md:700`–`712` | `design-check component-parity`; an exemption must be written with its reason (`:712`) |
| Cover every B* with a screen or flow, every E* with a visual state | `skills/forge/SKILL.md:714`–`719` | Two-way coverage check by ID class |
| Rotate posture, then gate | `skills/forge/SKILL.md:721`–`729` | `references/review-checklists.md#design` — dangling, W1; the real heading is `design-system.md` (`skills/forge/references/review-checklists.md:43`) |

**Required output.** `.forge/benchmarks.md`, `.forge/design/design-system.md`,
`.forge/design/screens/<name>.md` (one per screen), `state.json.index.nav`.

**Gate.** `design-check contrast`, `design-check tokens-used` (`skills/forge/SKILL.md:304`),
`forge-guard placeholders`, `design-check component-parity`.

### Phase 4 — Architecture (System Design)

Heading at `skills/forge/SKILL.md:731`. Purpose: decompose into slices, modules and foundations
with their dependencies (`:733`).

| Requirement | Where | Mechanism that forces depth |
|---|---|---|
| Decompose with four slicing rules | `skills/forge/SKILL.md:742`–`746` | Testable alone, ≤ ~10 new files, split if bigger, merge at 50 % shared code — each rule has a numeric or decidable trigger |
| Define every model field by field, plus validation schemas and API contracts with error codes | `skills/forge/SKILL.md:748`–`755` | "A field forgotten at this phase is a bug at implementation" (`:755`) |
| Declare the dependency graph through the CLI | `skills/forge/SKILL.md:759`–`763` | `state.js dep` refuses a dependency on a nonexistent slice, self-dependency, and anything closing a cycle (`:763`) |
| Compute `depended_on_by` and `impl_wave` | `skills/forge/SKILL.md:764` | `dependency-check.js check --write` derives them; hand-written waves are refused unless declared |
| Declare a finer schedule in the front matter, with a rationale | `skills/forge/SKILL.md:767`–`776` | A declared gap without a reason **fails**; with a reason it stays visible as a warning (`:776`) — but the template has no such field (W21) |
| Write `.forge/architecture.md` from the template | `skills/forge/SKILL.md:778`–`780`; `skills/forge/templates/architecture.md.tmpl:17`–`262` | 9 sections; §4.3 is literally "constraints in the database, and proofs that they hold" (`skills/forge/templates/architecture.md.tmpl:101`) |
| Execute the DDL, do not read it | `skills/forge/SKILL.md:782`–`819` | `ddl-exec all`: `completeness` (no engine), `execute` and `guards` (pglite). Three real defects that survived three gates are recorded (`:788`–`790`) |
| Declare the guards that must refuse | `skills/forge/SKILL.md:806`–`813` | `-- forge:ddl-refuse` marks a statement that must be rejected; the document names the forbidden operation, the check does not guess (`:815`) |
| Never report `pass` without executing | `skills/forge/SKILL.md:817`–`819` | Without pglite, `execute` and `guards` return `skipped`, never `pass`; `guards_declared: 0` is reported out loud |
| Rotate posture plus standards conformity | `skills/forge/SKILL.md:821`–`827` | `plan-validator` compares the architecture against `benchmarks.md` and the archetype |
| Gate | `skills/forge/SKILL.md:829`–`831` | `references/review-checklists.md#architecture` — dangling, W1 |

**Required output.** `.forge/architecture.md` (9 sections, DDL blocks executable), `state.json`
dependency fields, and — on approval — the rule set produced by call 2.

**Gate.** `ddl-exec all`, `dependency-check` (`skills/forge/SKILL.md:305`); then `rules-present`
and `rules-selftest` (10 checks) on the call-2 output (`skills/forge/SKILL.md:414`, `426`–`432`).

### Phase 5 — Implementation plan (per slice)

Heading at `skills/forge/SKILL.md:833`. Target: "a plan so precise that a weaker AI cannot get it
wrong" (`:835`). One slice at a time, a gate after each in Guided mode (`:837`).

| Requirement | Where | Mechanism that forces depth |
|---|---|---|
| No writer agent, deliberately | `skills/forge/SKILL.md:306`, `309`–`313` | Delegation is removed precisely because a plan passes every form check while describing nothing (`:309`–`311`); only `plan-validator` re-reads |
| Data contracts in the target stack's real syntax | `skills/forge/SKILL.md:839`–`846` | Every field must exist in Phase 4 — "no invented field" is a non-negotiable rule (`:846`) |
| Critical algorithms as pseudocode or real code | `skills/forge/SKILL.md:848`–`850` | Trigger is decidable: any B* with more than one branch or more than one step |
| Component plan, state management, pitfalls | `skills/forge/SKILL.md:852`–`866` | Each pitfall is tied to a B*/E* and phrased as an explicit contrast ("do not confuse X with Y — the correct behaviour is Z") (`:866`) |
| Ordered task checklist in 8 layers | `skills/forge/SKILL.md:868`–`878`; `skills/forge/templates/implementation-plan.md.tmpl:171`–`213` | Data, business logic, UI, integration, unit, component, integration/E2E, polish; the order is the requirement |
| Acceptance criteria individually verifiable, tied to B*/E*/C* | `skills/forge/SKILL.md:880`–`882`; `skills/forge/templates/implementation-plan.md.tmpl:215` | "Individually" excludes a criterion that needs the whole slice to be judged |
| Slice-specific test plan only; the common frame stays in Phase 6 | `skills/forge/SKILL.md:884`–`891` | Explicit anti-duplication rule (`:891`) |
| Coverage check before the gate | `skills/forge/SKILL.md:893`–`900` | `coverage-check slice` + `forge-guard placeholders`; `pass: false` means go back and complete, and the three verified properties are listed (`:898`–`900`) |
| Gate per slice | `skills/forge/SKILL.md:902`–`904` | `references/review-checklists.md#implementation-plan` — dangling, W1 |
| Fast Track instead of a human gate: 2 validators in parallel, scripts first | `skills/forge/SKILL.md:1024`–`1034` | Three agents with complementary blind spots (`:1026`–`1031`); deterministic scripts run before agents because a script finds in one second what an agent needs three reads for (`:1034`) |
| At most 2 revision attempts per artifact | `skills/forge/references/fast-track.md:72`, `275`; `skills/forge/scripts/state.js:1705` | Enforced in code (`if (n > 2) fail`), with the reason stated in the failure payload: beyond two attempts it is an upstream specification problem |

**Required output.** `.forge/plans/<slice>.md` (11 sections, 272-line template:
`skills/forge/templates/implementation-plan.md.tmpl:15`–`259`).

**Gate.** `coverage-check slice`, `forge-guard placeholders` (`skills/forge/SKILL.md:306`);
`plan-validator` in Fast Track. An agent nevertheless claims this path as its own output (W4).

### Phase 6 — Validation (test plan)

Heading at `skills/forge/SKILL.md:906`. Purpose: define the global test strategy and configure the
test environment (`:908`).

| Requirement | Where | Mechanism that forces depth |
|---|---|---|
| Install the test framework, the E2E tool, and Chrome MCP | `skills/forge/SKILL.md:910`–`914` | Three concrete installations, not a strategy statement |
| Write foundation tests before slice implementation | `skills/forge/SKILL.md:916`–`923` | Five foundations enumerated (design system, auth, error handling, i18n, API client), each with the kind of test it needs |
| Define the regression suite that runs before every merge | `skills/forge/SKILL.md:925`–`927` | One suite, one trigger point |
| Gate | `skills/forge/SKILL.md:929`–`931` | `references/review-checklists.md#validation` — dangling, W1 |
| Test-plan content: pyramid, per-ID-class coverage obligations, foundation tests, regression command, Chrome MCP per screen, environments | `skills/forge/templates/test-plan.md.tmpl:15`–`164` | 6 sections; §2.1 gives a mandatory test type per ID class (`:45`–`52`) |
| Scenario tests for temporal domains | `skills/forge/SKILL.md:960`; `skills/forge/references/scenario-tests.md`; `skills/forge/templates/scenario.md.tmpl:22`–`145` | A full-cycle scenario belongs to the slice that introduces the lifecycle, "not the last one" (`skills/forge/SKILL.md:960`) |

**Required output.** `.forge/test-plan.md` (6 sections) — **never instructed by the phase body**:
§6.1–6.4 (`skills/forge/SKILL.md:910`–`931`) never name the file, while the normative table does
(`:307`). See W2.

**Gate.** `consistency-check plans` (`skills/forge/SKILL.md:307`); checklist at
`skills/forge/references/review-checklists.md:124`.

### Phase 7 — Implementation

Heading at `skills/forge/SKILL.md:933`. Eleven ordered steps per approved slice (`:935`–`954`).

| Requirement | Where | Mechanism that forces depth |
|---|---|---|
| Check dependencies are implemented or mocked | `skills/forge/SKILL.md:937` | `state.js check-stale <slice>` |
| Read the plan and conventions only; consult one architecture section if ambiguous | `skills/forge/SKILL.md:938` | "Do not read the whole architecture" — a context budget stated as a rule |
| Implement strictly against contracts, algorithms and pitfalls | `skills/forge/SKILL.md:939` | Each of the three is a named section of the plan |
| Tests first where relevant, otherwise immediately after each layer | `skills/forge/SKILL.md:940` | TDD is conditioned, the fallback is bounded to "each layer" |
| Verify every acceptance criterion | `skills/forge/SKILL.md:941` | Criteria are the ones written in Phase 5 |
| Exit criterion is a gate, not a checklist | `skills/forge/SKILL.md:942`–`946` | `forge-exit` runs the real project commands **and** requires the slice to have test *cases*, not a test file; the recorded failure is 14 slices approved with no test at all (`:946`) |
| Route every finding with a domain | `skills/forge/SKILL.md:948`–`951` | `state.js finding --domain --severity`; a finding without a target is refused (`skills/forge/references/fast-track.md:283`) |
| Global consistency after the slice | `skills/forge/SKILL.md:952` | `consistency-check all`; the slice must not appear as a divergence |
| Status transition, then gate, before the next slice | `skills/forge/SKILL.md:953`–`956` | "Never move to the next slice" (`:956`) |
| Fast Track: no interruption of steps 1–9, milestone report every 3–5 slices | `skills/forge/SKILL.md:958` | The report must separate what was verified mechanically from what was not |

**Required output.** Source code outside `.forge/`, updated `.forge/audit/issues.md`, slice status
`implemented` then `validated`, test cases per slice.

**Gate.** `forge-exit`, `check-stale`, `consistency-check all`
(`skills/forge/SKILL.md:937`–`953`).

### Phase 8 — Final validation

Heading at `skills/forge/SKILL.md:962`. Six steps, no new deliverable (`:964`–`969`).

| Requirement | Where | Mechanism that forces depth |
|---|---|---|
| Run the full regression suite | `skills/forge/SKILL.md:964` | The suite defined in Phase 6 |
| Verify every PRD acceptance criterion | `skills/forge/SKILL.md:965` | Closes the traceability chain opened by the IDs |
| Last posture rotation over the whole project | `skills/forge/SKILL.md:966` | Mandatory for final validation (`skills/forge/SKILL.md:1018`) |
| `forge-guard all` | `skills/forge/SKILL.md:967` | One command, all guards |
| Set the project to `validated` | `skills/forge/SKILL.md:968` | State, not prose |
| Close the incident journal and generate the project audit | `skills/forge/SKILL.md:969` | `.forge/audit/issues.md` plus the audit report; the journal is the only input to v2's own improvement loop (`:1111`) |

**Required output.** No new document; `.forge/state.json` at `validated`, a closed incident
journal, an audit report.

**Gate.** `forge-guard all`; checklist at `skills/forge/references/review-checklists.md:144`.

---

## Cross-cutting protocols

| Protocol | Where | What makes it a mechanism rather than advice |
|---|---|---|
| State before prose | `skills/forge/SKILL.md:74`–`110`; `187`–`201` | `state.js start` is step 0 of every invocation; the six document levels (`:10`–`19`) and three planning units (`:21`–`25`) give every artifact one rank |
| Phase ownership is executable | `skills/forge/SKILL.md:33`–`36` | `PHASE_ARTIFACT_OWNERS`: `state.js register` refuses an artifact produced before its phase, and `forge-guard no_premature_artifacts` catches what is already on disk. Recorded failure: an architecture and 15 plans written while design was `draft`, with twelve checks green |
| Amendment, never renumber | `skills/forge/SKILL.md:450`–`485` | Heading map captured at approval; renumbering is **refused**; `--allow-renumber` requires `--renumber-reason`, which stays in state. Recorded failure: two endpoints inserted mid-document invalidated 17 cross-references in 8 plans, silently (INC-011, `:454`) |
| Cross-reference checking | `skills/forge/SKILL.md:482`–`485` | `consistency-check references` returns two verdicts: a named-but-absent target fails; an unnamed target is counted (276 on the test project) and never fails, because a check that everyone turns off protects nothing |
| Impact protocol | `skills/forge/references/impact-protocol.md:104`–`120`; `skills/forge/SKILL.md:994`–`1001` | 9 steps after a change, including per-document `stale`, hash recomputation, `dependency-check --full --write`, and a journal entry; the SKILL.md summary keeps 6 of the 9 (W17) |
| Change cascade rule | `skills/forge/references/impact-protocol.md:122` | A second change waits until the first one's consequences are fully propagated |
| Two validation modes | `skills/forge/SKILL.md:1005`–`1048` | Guided: two postures in-session, mandatory for PRD, architecture, final (`:1018`), justified by zero extra LLM calls (`:1020`). Fast Track: three agents chosen for complementary blind spots (`:1026`–`1031`), scripts before agents (`:1034`), strict JSON input/output contracts (`:1032`) |
| Fast Track entry is a command | `skills/forge/SKILL.md:1036`–`1046` | `forge-guard fast-track` refuses by naming what is missing; deliberately excluded from `forge-guard all` because `benchmarks` and `test_plan` belong to other phases (`:1043`) |
| Attempt ceiling in code | `skills/forge/scripts/state.js:1705` | `if (n > 2) fail` with `attempts_exhausted`, a rule and a fix; the comment states the limit is 2 and is in code rather than left to discipline |
| Arbitration between validators | `skills/forge/references/fast-track.md:263`–`266` | Disagreement rules by severity, then `REVISE`, then `BLOCK` plus human escalation for opposite verdicts |
| Memory boundary with `project-rules-architect` | `skills/forge/SKILL.md:203`–`222`, `368`–`448` | Forge is never the callee; two dated calls; four files it never writes; "a memory written by two writers loses data without leaving a trace" (`:442`) |
| Verification discipline | `skills/forge/SKILL.md:1146`–`1179` | 43 accumulated corrections, all of them verification errors rather than knowledge errors (`:1148`) |
| Audit loop | `skills/forge/SKILL.md:1101`–`1142` | Three files (`run-log.jsonl` append-only, `issues.md` human, `metrics.json` counters); ten mandatory log types (`:1121`–`1132`); cross-project clustering by normalized signature, exit code 2 on a structural problem (`:1142`) |
| A check is not validated until seen failing | `skills/forge/SKILL.md:1223` | Mutation discipline for the scripts themselves |
| `skipped` is not `pass` | `skills/forge/SKILL.md:819` | The optional-engine path returns a named non-verdict plus the install line |
| Deterministic scripts first | `skills/forge/SKILL.md:1196`–`1220` | 10 scripts, one role and one trigger moment each |
| State hygiene is measurable | `skills/forge/references/migration-v1-v2.md:15`, `:149`–`154` | The recognition test is a value over 2 000 characters in `state.json`; the migration procedure extracts before it migrates (`:5`) because migrating first produces "the defect, better formatted" (`:138`) |

---

## v2 weaknesses

### W1 — Six gate checklist anchors resolve to nothing

- **Ref** — Phase gates 1–6; `skills/forge/references/review-checklists.md`
- **Status** — verified
- **Severity** — critical
- **What** — Every phase ends with a gate instruction of the form
  `references/review-checklists.md#<anchor>`. None of the six anchors exists in the target file.
  The gate checklist is therefore unreachable by the written instruction, and the agent must
  either pick a section by guess or fall back to memory.
- **Evidence** — Cited anchors: `#prd` (`skills/forge/SKILL.md:557`), `#roadmap` (`:598`),
  `#design` (`:729`), `#architecture` (`:831`), `#implementation-plan` (`:904`), `#validation`
  (`:931`). Real headings, taken from the file: the `prd.md` block
  (`skills/forge/references/review-checklists.md:7`), `roadmap.md` (`:23`), `benchmarks.md`
  (`:34`), `design-system.md` (`:43`), `design/screens/<nom>.md` (`:82`), `architecture.md`
  (`:95`), `implementation-plan.md` (`:109`), `test-plan.md` (`:124`),
  `Sortie de Fast Track` (`:133`), `Validation post-implémentation` (`:144`). There is no heading
  whose slug is `design` or `validation`: the closest are `#design-systemmd-phase-33` and
  `#test-planmd-phase-6`. The check that would catch this cannot:
  `scripts/validate-repo.js`'s `no_dangling_skill_references` resolves *skill IDs*
  (`if (!skillIds.includes(ref))`) and never resolves an in-file anchor. CI runs that check on
  every push (`.github/workflows/ci.yml:20`), so the repository is green over a broken gate link.
- **Recommendation** — Cite anchors that exist (`#design-systemmd-phase-33`, or plain section
  names), and add an anchor-resolution case to `validate-repo.js` that fails on a `#fragment`
  pointing at a heading absent from the target file.

### W2 — Phase 6 never instructs writing its own deliverable

- **Ref** — Phase 6; `.forge/test-plan.md`
- **Status** — verified
- **Severity** — critical
- **What** — The normative table names `.forge/test-plan.md` as the Phase 6 deliverable, but the
  phase body has four steps — install tools, foundation tests, regression plan, gate — and none
  of them says to generate the file from the template. The gate then presents a checklist about a
  document the instructions never asked for. An agent that follows the body produces no
  `test-plan.md`, and the gate has no artifact to judge.
- **Evidence** — Deliverable declared at `skills/forge/SKILL.md:307`; phase body
  `skills/forge/SKILL.md:906`–`931` with no mention of the file, the template or
  `state.js register`; the template exists and is complete
  (`skills/forge/templates/test-plan.md.tmpl:15`–`164`); `quality-analyst` lists the file as an
  output (`skills/forge/agents/quality-analyst.md:125`), which is the only place it is assigned.
- **Recommendation** — Add an explicit generation step to §6.1 or a §6.0, with the template path
  and the `register` call, and make the gate fail when the deliverable is unregistered.

### W3 — `benchmarks.md` has no single owner

- **Ref** — Phases 1, 2, 3, 4; `.forge/benchmarks.md`
- **Status** — verified
- **Severity** — major
- **What** — The same document is produced in Phase 1, regenerated in Phase 3, read as an input in
  Phase 2 and Phase 4, and updated in Phase 6. Three agents claim it as an output and four
  documents give four different production moments. A regenerating step in Phase 3 overwrites
  what Phase 1 wrote; nothing says which version is authoritative.
- **Evidence** — Written in Phase 1 (`skills/forge/SKILL.md:548`), generated in Phase 3
  (`skills/forge/SKILL.md:613`), read as input by `scope-architect`
  (`skills/forge/agents/scope-architect.md:17`) and declared as its output (`:94`), read and
  declared as output by `ux-designer` (`skills/forge/agents/ux-designer.md:17`, `:195`), read by
  `systems-architect` (`skills/forge/agents/systems-architect.md:19`), owned by phase 3 in the
  canonical layout (`skills/forge/references/state-schema.md:204`), and extended in phases 1, 3, 4
  and 6 (`skills/forge/references/research-protocol.md:78`–`83`). The document itself says
  "it completes itself, it is not rewritten" (`skills/forge/references/research-protocol.md:85`),
  which no other file repeats.
- **Recommendation** — Name one producing phase and one producing agent, make every other phase an
  amendment through `state.js amend`, and state the "completes, never rewrites" rule in the
  normative table rather than only in the research protocol.

### W4 — Phase 5 has no writer, but an agent claims the plans as its output

- **Ref** — Phase 5; `skills/forge/agents/systems-architect.md`
- **Status** — verified
- **Severity** — major
- **What** — SKILL.md states that Phase 5 deliberately has no writing agent and that the plans are
  written by the orchestrator. `systems-architect`'s output table lists `.forge/plans/<slice>.md`
  as one of its deliverables. Two contracts disagree on who writes the most failure-prone document
  of the method.
- **Evidence** — "You write them yourself" (`skills/forge/SKILL.md:306`), with the reasoning that a
  plan is the easiest document to write in a vacuum (`:309`–`313`); output table row
  `Plan de slice | .forge/plans/<slice>.md` (`skills/forge/agents/systems-architect.md:154`), in
  an agent whose phase is 4. The agent also reads other slices' plans as input
  (`skills/forge/agents/systems-architect.md:23`), which contradicts the same phase ordering.
- **Recommendation** — Remove the plan row from `systems-architect`, or move the writing right to
  that agent and delete the "no writer" paragraph together with its justification.

### W5 — Phase 1's gate is verified by an agent whose phases exclude 1

- **Ref** — Phase 1 gate; `skills/forge/agents/client-liaison.md`
- **Status** — verified
- **Severity** — major
- **What** — The normative table makes `client-liaison --check` a verifier of the PRD, while the
  agent's front matter declares phases `[0, 4, 5, 7, 8]`. The agent contract and the phase table
  disagree on whether this agent is allowed to look at a Phase 1 document. An agent that respects
  its own front matter refuses the call the table mandates.
- **Evidence** — `skills/forge/SKILL.md:302` (verifier column, phase 1) against
  `skills/forge/agents/client-liaison.md:4` (`phases: [0, 4, 5, 7, 8]`), repeated in the
  normative agent table (`skills/forge/SKILL.md:1068`). The usage paragraph says the agent is used
  on the contract, on each gap report, and on the checkpoint before implementation
  (`skills/forge/SKILL.md:1094`) — the PRD is not in that list either.
- **Recommendation** — Either add phase 1 to the front matter and to `skills/forge/SKILL.md:1094`,
  or remove `client-liaison --check` from the Phase 1 verifier column.

### W6 — `client-liaison` forbids verdicts and emits one

- **Ref** — `skills/forge/agents/client-liaison.md`
- **Status** — verified
- **Severity** — major
- **What** — The agent's core rule is that it never returns a verdict, because a sub-agent that
  approves replaces the client with a fake client and makes the gate self-certifying. Its output
  schema contains a `verdict` field with `REVISE` and a `readable` boolean used as a pass/fail.
  The mechanism the rule protects is defeated by the schema the same file prescribes.
- **Evidence** — "You never return a verdict. You return a list of questions."
  (`skills/forge/agents/client-liaison.md:22`); schema `"verdict": "REVISE"` (`:111`) and
  `"readable": false` (`:115`); `readable` is defined as "can this client sign without asking a
  question" (`:119`) and returning `readable: true` with no question is explicitly allowed
  (`:123`). The prohibition is restated in `skills/forge/SKILL.md:1085`–`1087`.
- **Recommendation** — Drop `verdict` and `readable` from the schema and keep only the question
  list plus an explicit `questions: []` empty state, so the orchestrator decides.

### W7 — The attempt ceiling is stated three ways, and the prose contradicts the code

- **Ref** — Fast Track; `skills/forge/references/fast-track.md`; `skills/forge/scripts/state.js`
- **Status** — verified
- **Severity** — major
- **What** — The enforced limit is two revision attempts. One document says the command stops at
  the third attempt, another says it stops at two, and the code fails when the counter exceeds two.
  An agent reading only `SKILL.md` plans for one more attempt than the code allows.
- **Evidence** — `state.js fast-track --attempt` "stops at the third attempt"
  (`skills/forge/SKILL.md:1046`); "stops at **2** and refuses the third"
  (`skills/forge/references/fast-track.md:72`); limits table "**2**"
  (`skills/forge/references/fast-track.md:275`); gate item "no artifact exceeded 2 attempts"
  (`skills/forge/references/fast-track.md:349`); code `if (n > 2) { L.fail({ error:
  'attempts_exhausted' … }) }` (`skills/forge/scripts/state.js:1705`), whose own comment says
  "two attempts, not three".
- **Recommendation** — State the limit once, in the reference, and make `SKILL.md` point at it
  instead of restating a number.

### W8 — The Fast Track JSON contract omits the two fields the same file makes mandatory

- **Ref** — `skills/forge/references/fast-track.md`
- **Status** — verified
- **Severity** — major
- **What** — The canonical validator output lists `agent`, `verdict`, `findings` with severity
  `critical | major | minor`, `coverage_gaps`, `unreadable_without`. The limits table of the same
  file makes `severity: info` plus `prior_critical_resolved` mandatory so that an already-resolved
  finding cannot re-block. The schema has no field for either, so the mechanism described two
  pages later is unimplementable from the contract.
- **Evidence** — Schema at `skills/forge/references/fast-track.md:243`–`251`; mandatory row
  "`severity: info` + `prior_critical_resolved` — a resolved finding cannot re-BLOCK"
  (`skills/forge/references/fast-track.md:281`); both agents implement the fields anyway
  (`skills/forge/agents/quality-analyst.md:168`, `:173`;
  `skills/forge/agents/red-team.md:151`, `:156`), which makes the reference the stale copy.
- **Recommendation** — Add `info` to the severity enumeration and `prior_critical_resolved` to the
  schema, or state that the agents' schema is canonical and link to it.

### W9 — Every gate checklist exists twice, with divergent items

- **Ref** — Phases 1–6; `skills/forge/templates/*.tmpl` and
  `skills/forge/references/review-checklists.md`
- **Status** — verified
- **Severity** — major
- **What** — Each deliverable template ends with its own "Checklist de gate" section, and
  `review-checklists.md` holds a second checklist for the same deliverable. The two sets differ in
  item count and in content, and the phase gates point at the second one. Nothing says which set
  is binding, and a document can satisfy one while failing the other.
- **Evidence** — PRD: 10 items in `skills/forge/templates/prd.md.tmpl:189`–`198` against 13 in
  `skills/forge/references/review-checklists.md:9`–`21`; the template set omits the user-story
  format, the "points to clarify" item, the no-jargon item and the file-location item; the
  reference set omits nothing the template has but rewords every line. Architecture: template
  checklist at `skills/forge/templates/architecture.md.tmpl:262` against
  `skills/forge/references/review-checklists.md:95`. Plan:
  `skills/forge/templates/implementation-plan.md.tmpl:261` against
  `skills/forge/references/review-checklists.md:109`. Test plan:
  `skills/forge/templates/test-plan.md.tmpl:166` against
  `skills/forge/references/review-checklists.md:124`. Design: `benchmarks.md` has its own §7
  checklist (`skills/forge/templates/benchmarks.md.tmpl:104`) *and* a reference checklist
  (`skills/forge/references/review-checklists.md:34`), and the gate anchor points at neither.
  `design-quality.md` adds a third design list (`skills/forge/references/design-quality.md:121`
  –`134`), 12 items, overlapping the other two.
- **Recommendation** — Keep the reference file as the only checklist, replace each template
  section with a pointer to it, and make the phase gate anchor resolve (W1).

### W10 — Two validator agents share five verbatim blocks, and they have already drifted

- **Ref** — `skills/forge/agents/quality-analyst.md`, `skills/forge/agents/red-team.md`
- **Status** — verified
- **Severity** — major
- **What** — The two agents are supposed to have complementary angles ("what is missing" versus
  "what is false"), but five substantive blocks are copy-pasted between them: the
  `derived_from` table, the `derived_from`-absent paragraph, the `unreadable_without` budget
  paragraph, the verdict matrix, and the verdict/`unreadable_without` warning block. The drift is
  already visible.
- **Evidence** — `derived_from` rows: `skills/forge/agents/quality-analyst.md:28`–`30` versus
  `skills/forge/agents/red-team.md:26`–`28`; `state.js sync` sentence: `:32` versus `:30`;
  `unreadable_without` budget: `:43` versus `:41`; verdict matrix `PASS/REVISE/BLOCK`:
  `:181`–`183` versus `:164`–`166`; warning block: `:185`–`188` versus `:168`–`170`. Drift
  instance: `red-team.md:189` and `red-team.md:190` are the same sentence twice, a copy artefact
  the duplicate failed to clean.
- **Recommendation** — Extract the shared contract into one reference (input contract, verdict
  matrix, `unreadable_without` rule) and leave each agent file with only its own angle and its
  own question set.

### W11 — `red-team`'s mandate contradicts its own severity rule

- **Ref** — `skills/forge/agents/red-team.md`
- **Status** — verified
- **Severity** — major
- **What** — The mandate says never reassure, never say it is fine, and that a document with no
  identified problem is a failure of the agent. The severity rule says a real contradiction in an
  otherwise sound document is a `minor`, and that flooding the plan with maximum severity makes
  the signal unusable. An agent obeying the mandate produces the flood the rule forbids; an agent
  obeying the rule risks declaring a document problem-free, which the mandate calls a failure.
- **Evidence** — `skills/forge/agents/red-team.md:45`–`49` ("You never congratulate… a document
  with no identified problem is a failure on your part"), against
  `skills/forge/agents/red-team.md:136`–`140` ("a real contradiction in an otherwise sound
  document is a `minor`… flooding with maximum severity makes the signal unusable") and `:140`
  (`BLOCK` only if the plan cannot be implemented as is, or a `critical` cancels a PRD rule).
- **Recommendation** — Replace "no problem is a failure" with a decidable duty (state what was
  checked and report `coverage_gaps`), so silence is distinguished from a clean document. W8's
  missing `info` severity is the field that would carry it.

### W12 — `forge-implementer` cites plan sections off by one

- **Ref** — Phase 7; `skills/forge/agents/forge-implementer.md`
- **Status** — verified
- **Severity** — major
- **What** — Three hard rules point the implementer at plan sections that hold something else:
  "data contracts (§3)" when §3 is algorithms, "algorithms (§4)" when §4 is the component plan,
  "pitfalls (§8)" when §8 is dependencies. The implementer is told to respect contracts, to
  implement algorithms exactly and to reread pitfalls before each code section — at three wrong
  addresses, in a document it is required to read selectively.
- **Evidence** — `skills/forge/agents/forge-implementer.md:81`–`83`; actual sections: data
  contracts `§2` (`skills/forge/templates/implementation-plan.md.tmpl:46`), algorithms `§3`
  (`:71`), component plan `§4` (`:85`), pitfalls `§7` (`:153`), dependencies `§8` (`:163`). The
  same off-by-one appears in `skills/forge/agents/quality-analyst.md:88`.
- **Recommendation** — Cite sections by title rather than number, or correct to §2/§3/§7 and add
  the numbering to a single table both agents read.

### W13 — `forge-implementer` says all output is inside `.forge`, then writes code outside it

- **Ref** — Phase 7; `skills/forge/agents/forge-implementer.md`
- **Status** — verified (contradiction) / inferred (the consequence)
- **Severity** — major
- **What** — The output section lists two rows: slice code goes to the target project's source
  tree *outside* `.forge/`, and the validation report goes to `.forge/audit/issues.md`. The
  sentence immediately below states that everything goes in `.forge/` and nothing elsewhere. A
  guard exists that relocates misplaced deliverables into `.forge/`
  (`forge-guard strays --relocate`), so the wrong reading is executable: it can move source code
  into the state directory.
- **Evidence** — `skills/forge/agents/forge-implementer.md:145` (row: `Code de la slice |
  l'arborescence source du projet cible (hors .forge/)`) against `:148` ("Everything in
  `.forge/`, and nothing elsewhere"); the relocation command is documented at
  `skills/forge/SKILL.md:1129` and `skills/forge/README.md:34`.
- **Recommendation** — Scope the sentence to deliverables that are Forge documents, and state
  explicitly that source code is not a deliverable and is never relocated.

### W14 — Scenario narratives are read from one home and written to another, registered nowhere

- **Ref** — Phases 6–8; `skills/forge/agents/scenario-tester.md`
- **Status** — verified
- **Severity** — major
- **What** — The agent reads existing narratives from `.forge/scenarios/`, writes them to
  `test/scenarios/`, and the template's front matter declares `implementation:
  test/scenarios/…`. `.forge/scenarios/` is not in the canonical layout, is not one of the two
  allowed non-deliverable folders, and no script mentions it. The read path therefore points at a
  directory nothing produces, while the real narratives live outside `.forge/` and cannot be
  registered, so no gate sees them.
- **Evidence** — Input `skills/forge/agents/scenario-tester.md:17`; outputs `:79`–`80` and JSON
  paths `:90`–`91`; `skills/forge/references/scenario-tests.md:57`–`58`;
  `skills/forge/templates/scenario.md.tmpl:12`; canonical layout without a scenario key
  (`skills/forge/references/state-schema.md:199`–`211`, non-deliverable folders limited to
  `.forge/audit/` and `.forge/.tmp/` at `:211`); no `scenarios` occurrence in
  `skills/forge/scripts/coverage-check.js` or `skills/forge/scripts/forge-guard.js`.
- **Recommendation** — Pick one home, add it to `CANONICAL_LAYOUT` if the narrative is a
  deliverable, and give the Phase 7 exit criterion a check that reads it.

### W15 — The contract requires one row per slice, and is signed before slices exist

- **Ref** — Phase 0; `skills/forge/templates/contract.md.tmpl`
- **Status** — verified
- **Severity** — major
- **What** — Contract §1 must contain one row per slice, in the client's words. Slices are
  produced in Phase 4, four phases after the contract is signed, and the contract is the document
  whose signature closes the negotiation. The Phase 0 writer must therefore invent slice names or
  leave the table empty; a later correction edits an approved, signed document without going
  through the amendment contract.
- **Evidence** — "One line per slice" with the table header `Slice | What the client will get |
  For whom` (`skills/forge/templates/contract.md.tmpl:28`–`33`) against the Phase 0 instruction to
  generate and sign (`skills/forge/SKILL.md:339`–`343`) and the Phase 4 instruction to decompose
  into slices (`skills/forge/SKILL.md:735`–`746`). The contract's own §1 says it must be readable
  without a glossary, which a pre-slice vocabulary cannot guarantee.
- **Recommendation** — Make §1 a list of client-visible outcomes derived from the PRD, and add a
  post-Phase-4 "slice mapping" appendix that is amended, not rewritten.

### W16 — `V*` validation IDs are required by the test plan and created by no PRD section

- **Ref** — Phases 1 and 6; ID taxonomy
- **Status** — verified
- **Severity** — major
- **What** — The principles introduce a fourth ID class, `V1, V2… for validations`, and the test
  plan makes a coverage obligation per ID class including `V*`. The PRD template defines only B*,
  E* and C*, its gate checklist lists only those three, and the test plan's own gate checklist
  omits `V*`. A traceability axis is announced, consumed, and never produced.
- **Evidence** — `skills/forge/SKILL.md:33` (`V1, V2… pour les validations`); coverage obligation
  `| V* (validation) | 1+ test unitaire + 1+ test composant |`
  (`skills/forge/templates/test-plan.md.tmpl:50`); PRD template ID sections
  (`skills/forge/templates/prd.md.tmpl:65`, `:75`, `:85`) and PRD gate items (`:192`–`194`);
  test-plan gate items naming only `B*, E*, C*` (`skills/forge/templates/test-plan.md.tmpl:169`).
- **Recommendation** — Either define a `V*` section in the PRD with its own gate item, or remove
  `V*` from the taxonomy and from the coverage table.

### W17 — `SKILL.md`'s impact summary drops 4 of the protocol's 9 steps

- **Ref** — Change management; `skills/forge/references/impact-protocol.md`
- **Status** — verified
- **Severity** — major
- **What** — The reference defines nine post-change steps. The summary in the routing document has
  six, and the three it drops are the ones that make drift detectable: hash recomputation,
  `dependency-check --full --write`, and the journal entry. An agent that reads only the summary
  marks documents `stale` and runs `forge-guard all`, and never updates the hashes that
  `check-stale` compares.
- **Evidence** — Summary `skills/forge/SKILL.md:994`–`1001`; full list
  `skills/forge/references/impact-protocol.md:104`–`120`, with hash at `:111`, dependency write at
  `:116`, journal at `:120`. `check-stale` is the command the summary does keep (`:999`), which
  makes the missing hash step self-defeating.
- **Recommendation** — Replace the summary with the numbered list and a pointer, or keep six steps
  and add "then steps 4, 6 and 9 of the protocol".

### W18 — Two severity vocabularies with no mapping

- **Ref** — Findings; `skills/forge/scripts/state.js`, `skills/forge/agents/scenario-tester.md`
- **Status** — verified
- **Severity** — major
- **What** — The finding command defaults to `mineur`, French, while validators emit
  `critical | major | minor` and one agent's examples use `majeur`. No file maps the two
  vocabularies, and nothing validates the value, so a finding recorded as `majeur` is neither the
  default nor the validator vocabulary. Any aggregation by severity silently splits one level into
  two spellings.
- **Evidence** — `severity: flags.severity || 'mineur'` (`skills/forge/scripts/state.js:1826`);
  agent example `--severity=majeur` (`skills/forge/agents/scenario-tester.md:36`, also `:102`);
  validator enumeration `critical | major | minor`
  (`skills/forge/references/fast-track.md:243`); the finding command is specified without an
  allowed set (`skills/forge/SKILL.md:950`).
- **Recommendation** — Declare one enumeration in the state schema, validate it in `state.js`, and
  make the audit aggregation group on it.

### W19 — `AGENTS.md` has two owners in one table

- **Ref** — Memory boundary; `skills/forge/references/skill-boundaries.md`
- **Status** — verified
- **Severity** — major
- **What** — The ownership table assigns `AGENTS.md` to `project-rules-architect` in one row and
  to "the agent" (with the three memory files) in the next. `SKILL.md` resolves the same boundary
  cleanly — rules and `AGENTS.md` on one side, the three memory files on the other — so the
  reference is the copy that reintroduces the double writer the design exists to prevent.
- **Evidence** — `skills/forge/references/skill-boundaries.md:14` (`project-rules-architect` owns
  `AGENTS.md`, `.opencode/rules/*.md`) and `:15` (the agent owns `AGENTS.md`, `SESSION_LOG.md`,
  `DECISIONS.md`, `LEARNINGS.md`); correct split at `skills/forge/SKILL.md:209`–`210`; the cost of
  two writers is stated at `skills/forge/SKILL.md:442`.
- **Recommendation** — Delete `AGENTS.md` from the agent row and point both rows at
  `skills/forge/SKILL.md:209`–`210`.

### W20 — The normative agent-per-phase table omits phases 0, 7 and 8

- **Ref** — `skills/forge/SKILL.md` per-phase table
- **Status** — verified
- **Severity** — major
- **What** — The table is declared normative precisely because guessing an agent file name
  produces a deliverable whose absence never fails. It has rows for phases 1 to 6 only. Phase 0,
  Phase 7 and Phase 8 have no designated agent, so the implementation phase — the one where the
  wrong agent is most costly — is back to guessing. The table's own justification cites two wrong
  guesses, one of them for Phase 4.
- **Evidence** — `skills/forge/SKILL.md:300`–`307` (six rows); the "this table is normative"
  paragraph and the two recorded wrong guesses at `:288`–`298`; the enclosing check that the table
  cannot desynchronise itself (`:319`–`321`) covers only the names it lists, so an omitted phase
  is invisible to it. `forge-implementer` is declared for phases 7 and 8 in the agent table
  (`:1067`) but never appears in the per-phase table.
- **Recommendation** — Add the three rows (`contract.md` and the four memory files for 0,
  `forge-implementer` for 7 and 8) and extend `validate-repo.js` to require one row per phase.

### W21 — The architecture front matter cannot carry the schedule the gate requires

- **Ref** — Phase 4; `skills/forge/templates/architecture.md.tmpl`
- **Status** — verified
- **Severity** — major
- **What** — `SKILL.md` requires a finer implementation schedule to be declared in the
  architecture's front matter as `impl_waves` plus `impl_waves_rationale`, and fails the artifact
  when the rationale is absent. The template's front matter has four keys and neither of them.
  Every project therefore starts in the state `SKILL.md` calls silently wrong, and a writer must
  invent keys to escape it.
- **Evidence** — Required keys and their refusal rule at `skills/forge/SKILL.md:767`–`776`;
  template front matter with `type`, `status`, `generated_at`, `derived_from` only
  (`skills/forge/templates/architecture.md.tmpl:1`–`6`); the field is written back by
  `dependency-check --write` (`skills/forge/SKILL.md:764`), which is the overwrite the declaration
  is meant to prevent.
- **Recommendation** — Add both keys, commented out, to the template front matter, so the choice
  is presented rather than hidden.

### W22 — The body runs `design-check tokens`, the gate requires `tokens-used`

- **Ref** — Phase 3; `skills/forge/scripts/design-check.js`
- **Status** — verified
- **Severity** — major
- **What** — The Phase 3 body, after the token-class declaration, runs `design-check contrast` and
  `design-check tokens`. The normative table requires `design-check tokens-used`. These are two
  different checks in the script: `tokens` verifies declared tokens exist, `tokens-used` verifies
  that tokens cited by screens exist. An agent that follows the body passes the body and fails the
  gate, and the failure is on the check the body never named.
- **Evidence** — Body `skills/forge/SKILL.md:668`–`671` (`design-check.js tokens`, line 670); gate
  column `design-check tokens-used` (`skills/forge/SKILL.md:304`); distinct commands in
  `skills/forge/scripts/design-check.js:470` (`command: 'tokens'`) and `:516`
  (`command: 'tokens-used'`), dispatched at `:918`.
- **Recommendation** — Add `tokens-used` to the body's command block, or make the body the only
  place commands are listed and have the table point at it.

### W23 — Systemic French/English corruption in normative files

- **Ref** — `skills/forge/**` (agents, references, templates)
- **Status** — verified (sample, not exhaustive)
- **Severity** — major
- **What** — A translation pass replaced French words with unrelated English ones, including inside
  a title, inside a validator question and inside a table header. The corrupted words are load-
  bearing: the same token appears in four files where a validator prompt depends on it, and one
  file's H1 no longer parses. These are the files agents read to decide what to check.
- **Evidence** — `attendance` for *attendus*, 15 occurrences: `skills/forge/references/archetypes.md:47`,
  `:65`, `:84`, `:103`, `:122`, `:141`, `:160`, `:181`, `:237`;
  `skills/forge/agents/plan-validator.md:52`, `:64`, `:70`, `:106`;
  `skills/forge/templates/benchmarks.md.tmpl:59`, `:77`. `# Qualité de design -orithmic
  anti-générique` (`skills/forge/references/design-quality.md:1`). `En Kenntnis` and `est sichr`
  (`skills/forge/references/research-protocol.md:33`, `:36`). `UneFunctionalité` and `notreGain`
  (`skills/forge/agents/premise-challenger.md:20`, `:69`). `ethnogrammes`, `opened`, `facets`
  (`skills/forge/references/module-prioritization.md:41`, `:36`, `:60`). `point mais il n'y a
  jamais` (`skills/forge/references/state-schema.md:5`). `ne verra jamais ne verra jamais`
  (`skills/forge/references/fast-track.md:215`). Duplicated sentence
  (`skills/forge/agents/red-team.md:189`–`190`).
- **Recommendation** — Repair the tokens in place and add a repository check that fails on a
  token outside the declared language of each file; a spell-check cannot catch `attendance`
  because it is a valid English word.

### W24 — Stale counts in both READMEs, and the guard covers only `SKILL.md`

- **Ref** — `README.md`, `skills/forge/README.md`, `scripts/validate-repo.js`
- **Status** — verified
- **Severity** — minor
- **What** — Both READMEs understate the skill's contents on every counted dimension. The check
  that exists for exactly this drift (`declared_lists_match_files`) reads `SKILL.md` only, so the
  READMEs are outside its scope and stay wrong while CI is green.
- **Evidence** — `skills/forge/README.md:123` ("8 contrats d'agents", actual 11),
  `:132` ("9 gabarits", actual 12), `:143` ("7 protocoles", actual 12), `:151` ("6 scripts",
  actual 10 plus `lib/`); `README.md:123` and `:151` repeat the 8 and the 6; the guard's scope is
  visible at `scripts/validate-repo.js:389`–`397` (`rel`, `spec.label` iterating over `SKILL.md`
  lists).
- **Recommendation** — Extend the check to the READMEs, or delete the counts from them.

### W25 — `premise-challenger` cadence is stated three ways

- **Ref** — Phases 1–4; `skills/forge/agents/premise-challenger.md`
- **Status** — verified
- **Severity** — minor
- **What** — The agent's phase range is `1–4`, the routing document says it triggers at the end of
  phases 1, 2 and 3, and Phase 1 alone calls it twice (mid-interview, then on the PRD). The agent
  file agrees with the "end of 1, 2, 3" version and also lists a phase 4 trigger. Three statements,
  one of which (`1–4` as a range) reads as a fourth invocation.
- **Evidence** — `skills/forge/SKILL.md:1065` (`1–4`), `:1070` ("end of Phases 1, 2 and 3"),
  `:315` and `:493` (twice in Phase 1); `skills/forge/agents/premise-challenger.md:40`–`47`
  (phase 1 twice, then phases 2, 3, 4, "on demand"; default frequency "end of each phase 1, 2
  and 3").
- **Recommendation** — State the invocation list once as `1 (×2), 2, 3, plus on demand in 4`.

### W26 — `research-protocol` schedules a pass its own anti-objective forbids

- **Ref** — `skills/forge/references/research-protocol.md`
- **Status** — verified (contradiction) / inferred (which one is intended)
- **Severity** — minor
- **What** — The "When" table schedules a research pass in Phase 6, which by construction happens
  after the PRD is frozen. The anti-objective table lists "do the research after the PRD is
  frozen" as a prohibited practice, with the reason that the PRD is the moment when the good
  questions are still open. Both tables are in the same file, fifteen lines apart.
- **Evidence** — `skills/forge/references/research-protocol.md:83` (Phase 6 row) against `:98`
  (anti-objective row).
- **Recommendation** — Narrow the Phase 6 row to "test-scenario selection only, no new product
  research", or delete it.

### W27 — `sync` has two owners for one operation

- **Ref** — State reconciliation; `skills/forge/references/state-schema.md`
- **Status** — verified
- **Severity** — minor
- **What** — The provenance table names two commands for reconciling state with front matter, and
  the routing document names a third context for the same operation. Both commands exist, so the
  duplication is silent: whichever one a reader picks, the other looks unused.
- **Evidence** — `divergences | forge-guard.js sync, state.js sync`
  (`skills/forge/references/state-schema.md:227`); `state.js sync | Réconcile état ↔ front matter`
  (`skills/forge/SKILL.md:1202`); `forge-guard.js sync` in the canonical command list
  (`skills/forge/SKILL.md:197`).
- **Recommendation** — Name one command as the operation and the other as its guard wrapper, and
  say so in the provenance table.

### W28 — `ux-designer`'s internal phase numbers disagree with `SKILL.md`

- **Ref** — Phase 3; `skills/forge/agents/ux-designer.md`
- **Status** — verified
- **Severity** — minor
- **What** — The agent labels its sections "Phase 3.1", "3.2", "3.3"; `SKILL.md` numbers the same
  work 3.3, 3.4 and 3.5. A reader who follows the agent's numbering to find "Phase 3.1 design
  system" lands on "direction visuelle" in `SKILL.md` and concludes the document is missing.
- **Evidence** — `## Design system (Phase 3.1)` (`skills/forge/agents/ux-designer.md:41`),
  `## Écrans et flows (Phase 3.2)` (`:117`), `## Validation design (Phase 3.3)` (`:179`) against
  `#### 3.1 Direction visuelle` (`skills/forge/SKILL.md:606`), `#### 3.3 Design system` (`:631`),
  `#### 3.4 Écrans et flows` (`:686`), `#### 3.5 Validation design` (`:714`).
- **Recommendation** — Cite sections by title, as the template does, and delete the local numbers.

### W29 — `product-analyst` claims `roadmap.md` while being barred from MVP scope

- **Ref** — Phase 2; `skills/forge/agents/product-analyst.md`
- **Status** — verified
- **Severity** — minor
- **What** — The agent's output table lists `.forge/roadmap.md`, and its "what you do not do"
  section forbids deciding what enters the MVP and assigns that to `scope-architect`. The
  normative table also assigns the roadmap to `scope-architect`. The output row contradicts two
  other statements in the same file and one in `SKILL.md`.
- **Evidence** — Output `skills/forge/agents/product-analyst.md:144`; prohibition `:154`;
  normative assignment `skills/forge/SKILL.md:303`.
- **Recommendation** — Remove the row, or narrow it to "contributes the feature inventory that the
  roadmap scores".

### W30 — `$` and `§` section notation mixed inside one template

- **Ref** — `skills/forge/templates/implementation-plan.md.tmpl`
- **Status** — verified
- **Severity** — minor
- **What** — The same template writes one cross-reference as `§6` and fifteen others as `$2.1`,
  `$3.`, `$4.2`, `$5`, `$9`, `$10`, `$11`. The dollar form is a corrupted section sign, so a
  reader searching for "§4.2" finds only the one correct instance.
- **Evidence** — `§6` at `skills/forge/templates/implementation-plan.md.tmpl:19`; `$2.1` at `:117`,
  `$2.1`/`$2.2`/`$2.3` at `:175`–`177`, `$3.` at `:182`, `$5` at `:184`, `$4.2`/`$4.3`/`$4.4` at
  `:188`–`190`, `$2`/`$3`/`$9`/`$10`/`$11` at `:265`–`269`.
- **Recommendation** — Normalise to `§` and add the notation to the template's usage note.

### W31 — The contract cites `SKILL.md § 35`

- **Ref** — `skills/forge/templates/contract.md.tmpl`
- **Status** — verified
- **Severity** — minor
- **What** — A client-facing template justifies a silence rule by citing section 35 of `SKILL.md`.
  `SKILL.md` has no section 35; 35 is a line number, and the numbered sections of that file are
  phase subsections. The citation cannot be followed by the reader it is meant to reassure.
- **Evidence** — `skills/forge/templates/contract.md.tmpl:97`; the heading list of
  `skills/forge/SKILL.md` (lines 6–1274) contains no numbered section.
- **Recommendation** — Replace with a titled reference ("the silence rule, § After signature") or
  drop the citation from a document addressed to a non-technical client.

---

## Rejected candidates

| Candidate | Why it is not recorded as a defect | Evidence |
|---|---|---|
| `SKILL.md` is too long (1289 lines, 84 385 bytes) | It is the routing document, and the delegation is real: 12 references, 12 templates, 10 scripts plus their library, each with a role and a trigger in one table. Length alone is not a mechanism failure; the failures found are broken links and duplicated facts (W1, W9), not volume | `skills/forge/SKILL.md:1253`–`1273` (reference table), `:1196`–`1220` (script table) |
| The incident-narrative style ("Constaté, INC-011", "43 corrections") | It is the mechanism that turns a rule into a check: each rule carries the failure it was written to prevent, which is what makes the refusal arguable. Removing it would leave preferences | `skills/forge/SKILL.md:292`–`298`, `:452`–`454`, `:786`–`790`, `:946`, `:1148` |
| Long bilingual `description` in the front matter | Trigger surface, not padding: it enumerates platforms and actions so the skill is selected for the right request | `skills/forge/SKILL.md:1`–`4` |
| `premise-challenger` blocking on a single `critical` | Bounded by design: the user's decision overrides the agent, and the override is recorded as an assumed gap | `skills/forge/agents/premise-challenger.md:143`, `skills/forge/SKILL.md:1070` |
| DDL execution (`ddl-exec`) and `forge-exit` as gates | Both are executable gates with recorded failures they were built to catch; `forge-exit` distinguishes "a test file" from "test cases", which no review can | `skills/forge/SKILL.md:782`–`819`, `:942`–`946` |
| `skipped` treated as a distinct verdict from `pass` | Deliberate and correct: an optional engine that cannot run must not certify | `skills/forge/SKILL.md:819` |
| `design-quality.md` §3 phrased as prohibitions ("Pas de blanc pur") | Considered as an inverted-checklist defect and rejected: a tick reads as "absence confirmed", the same semantics as the positive gate list, and the file has its own gate list at `:121`–`134`. The real defects there are duplication (W9) and the corrupted H1 (W23) | `skills/forge/references/design-quality.md:60`–`91`, `:121`–`134` |
| Two READMEs (repository and skill) | Two audiences, two scopes; the defect is the stale counts (W24), not their existence | `README.md:123`, `skills/forge/README.md:123` |
| Eleven agents is too many for one method | Not assessable as a defect: the agent set maps to declared phases and each file carries an input contract, an output contract and a "does not do" list. The measurable problems are duplication (W10) and phase mismatches (W5, W20) | `skills/forge/SKILL.md:1056`–`1068` |
| The 276 undeclared cross-reference targets | The check treats them as a count, never a failure, and says why: a check that fails 276 times gets switched off. A deliberate threshold, not a hole | `skills/forge/SKILL.md:485` |

---

## Open questions

| # | Question | Why it cannot be settled from the clone | What would settle it |
|---|---|---|---|
| Q1 | Did `.forge/scenarios/` ever exist in a project produced by v2? | No v2-managed `.forge/` exists in the clone; the path appears only as an agent input | One real project's `.forge/` tree, or an audit log containing a scenario path |
| Q2 | Was the 2-attempt ceiling ever reached in practice? | `state.js:1705` is the only trace; attempt counters live in a project's `state.json` | A project `state.json` with a non-empty `fast_track.attempts` |
| Q3 | Did any real project use `V*` IDs? | The clone holds templates, not filled documents | A filled `prd.md` and `test-plan.md` from a v2 run |
| Q4 | Were contract §1 slice rows back-filled after Phase 4? | Requires the signed contract and the architecture of the same project | Both documents from one run, compared by date |
| Q5 | Where did the corruption in W23 come from? | `git rev-list --count HEAD` = 1: the clone has no history to diff | The upstream repository's history, or a pre-translation snapshot |
| Q6 | Does any renderer resolve `#design` to `#design-systemmd-phase-33`? | Anchor resolution is renderer-specific; GitHub-flavoured slugs do not prefix-match, others were not tested | The renderers actually used by the target agents (OpenCode, Claude Code, Codex) |
| Q7 | Is `benchmarks.md` rewritten or extended in practice? | Depends on the Phase 3 agent's behaviour, not on the text | Two successive versions of the file from one project |
