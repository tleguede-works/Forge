# Improvements to study

This file lists improvements that are decided in intent but not yet designed. Each item states the goal, what the owner asked for, what Forge already provides, and the questions the study must answer. An item leaves this list when its design is written into the manifest and its tests exist.

Status values: `to study`, `design written`, `implemented`.

## Priority order (analysis, 2026-10-19)

| Rank | Item | Why this rank | Effort | Depends on |
|---|---|---|---|---|
| 1 | I-006 Full audit (first pass done: `docs/AUDIT-2026-10-19.md`) | Cheap, and it finds defects that would corrupt every later test. Two real holes are already known (see the item) | Medium | none |
| 2 | I-004 Regulatory compliance (design discussion first) | It changes the phase list, so it must be decided before the end-to-end test; the demo target (banking) is a regulated sector | Medium, mostly design | I-006 findings |
| 3 | I-005 End-to-end test: Togo mobile banking demo | Proves the system on a real case and supports the owner's business goal; it should exercise compliance, so it follows rank 2 | Medium | I-006, I-004; needs an environment with real sub-agents |
| 4 | I-001 Verification before every commit | Well bounded, high value in the build phase, but the end-to-end test stops before the build, so it can wait | Medium | I-006 |
| 5 | I-002 Existing project: add features | Highest strategic value for client work, and the largest design question (extend Forge or a separate system) | Large | I-006; study of code-graph tools |
| 6 | I-003 Existing project: transform or migrate | Builds on the analysis engine of I-002 and adds parity and migration planning | Large | I-002 |

Reading of the order: audit and decide the structure first (I-006, I-004), prove it on a real case (I-005), then add the build-phase guard (I-001), then open the brownfield tracks (I-002, I-003), which should not start before the audit and the test show how sound the greenfield base is.

---

## I-001 Mandatory verification before every commit (to study)

### Goal

During the build phase, Forge never allows a commit before a set of checks has run on the code about to be committed and every problem found has been handled. The process is systematic: it runs on every commit, not on request.

### What the owner asked for

1. **Code review**: quality of the code, consistency with the Forge Rules, respect of good practices.
2. **Tests**: the necessary tests are executed and pass.
3. **Security**: detect potential vulnerabilities and mistakes that create security problems.
4. **Other relevant checks**: identify the additional checks needed for quality, reliability and maintainability.
5. **A specialised code-review agent**: define its role, the rules it verifies, its method, and how it interacts with the other Forge components.
6. **Handling**: problems found are processed before the commit goes ahead.

These are ideas to deepen, not decisions. The study decides the mandatory checks, the tools, and the conditions that allow or block a commit.

### What Forge v3 already provides

| Building block | Where | Relevance |
|---|---|---|
| `forge slice done` with evidence `<command> : <result>` | CLI | Records test evidence per slice, not per commit |
| Hash-bound review reports and two-reviewer gate | CLI, `forge-qa`, `forge-redteam` | Reusable pattern: a report bound to what was reviewed |
| `forge rules audit` and the project's `quality-gates.md` | forge-rules | Defines the project's own gate commands (lint, types, tests, coverage, duplication, vulnerabilities, review) |
| Rules phase (`rules-report`, gate runs the audit, drift protection) | CLI, forge-rules | Guarantees that `quality-gates.md` exists and passes the audit before the build starts |
| `forge-rules` template `code-review.md` | forge-rules templates | Existing review rules a project can inherit, including "a reviewer never approves their own change" |
| `forge-builder` agent | agents | The author whose work is checked |
| Memory trigger 6 "before a commit" | forge-memory | Currently a conditional trigger, listed as J3 in `docs/ESCAPE-HATCH-AUDIT.md` |
| Claude Code hooks and OpenCode plugin | hooks | Possible enforcement points; `PostToolUse` and `PreCompact` exist today, a pre-commit event does not |

### Questions the study must answer

**1. Where is the commit blocked**
- A git `pre-commit` hook, an agent-side hook on the shell tool when it runs `git commit`, a `forge commit` command that wraps git, or a combination.
- Behavior when the commit is made outside an agent, or with `--no-verify`.
- How the hook behaves on Windows and in both OpenCode and Claude Code.

**2. What the mandatory checks are, and where the list comes from**
- Fixed Forge list, or derived from the project's `quality-gates.md` (commands per stack), or both with a fixed minimum.
- How Forge reads the project's gate commands reliably.
- Candidate checks to evaluate: lint, format, type check, build, unit and integration tests, coverage threshold or ratchet, duplication, dependency vulnerability audit, secret scan, static security analysis, license check on new dependencies, migration safety, API contract drift, banned patterns from the Forge Rules, placeholders left in code, plan task ticked and slice scope respected, layout region tokens built, commit message convention, large or generated files, accessibility and performance budgets where the stack supports them.
- Which checks block, which only warn, and why.

**3. The code-review agent**
- Role and independence from `forge-builder`; how it differs from `forge-qa` (what is missing) and `forge-redteam` (what is contradictory).
- Inputs: the staged diff, the plan of the slice, the architecture contracts, the project's rule files.
- What it verifies: compliance with each Forge Rule, conformity to the plan, scope growth, test quality (do the tests fail without the code), maintainability, readability, error handling, security-sensitive changes.
- Method: how it reads a large diff within a small context window; whether it reviews per file or per slice.
- Output: a structured report with findings, severity and evidence, bound to the hash of the staged content.
- Who fixes findings, and how a fix triggers a new review.
- Name, tools and permissions; how the orchestrator delegates to it.

**4. Security**
- Tools per stack and how Forge discovers them; what happens when a tool is absent (block, or record the gate as `absent` with the install command, as forge-rules does for quality gates).
- Handling of secrets found in a diff.
- False positives: dismissal rule, with a recorded decision as for review findings.

**5. Blocking and override**
- Severity policy that blocks a commit.
- Whether an override exists, who can use it, and what it records (the user's own words, a decision entry, the journal).
- Whether work-in-progress commits follow a lighter path.

**6. Binding the checks to the commit**
- Proving that what was checked is what gets committed (hash of the staged tree).
- Behavior on `commit --amend`, rebase and merge commits.
- Relationship between commit granularity and slices.

**7. Interaction with the rest of Forge**
- Relation to `forge slice done`: whether it requires a passing pre-commit run.
- Memory: `forge memory checkpoint` becomes part of the pre-commit step, which turns trigger 6 from conditional into mechanical.
- Journal and client-mode report: how blocked commits and handled findings appear.
- Overlap with CI so that the same checks are not defined twice.

**8. Cost and limits**
- Time budget of a commit, incremental checks on the changed files, behavior with small context windows.
- Failure modes: a flaky test, a missing tool, an offline machine.

**9. Escape-hatch review**
- Add the new shortcuts to `docs/ESCAPE-HATCH-AUDIT.md` and to `tests/adversarial.sh` before implementation is called done.

### Expected output of the study

1. A design note that fixes the enforcement point, the mandatory check list, the blocking policy and the review agent's contract.
2. An update of the manifest and of `docs/STATUS.md`.
3. Test scenarios, including adversarial ones, written before the implementation.
4. A breakdown into implementation tasks.

---

## I-002 Existing project: add features (to study, no development before a decision)

### Goal

Let Forge take over a codebase it did not create and add features without regressions: understand structure, dependencies, architectural choices, the reasons behind them, and the constraints accumulated over time, then anticipate the consequences of a change before writing code.

### What the owner asked for

- A mechanism that analyses an existing project: structure, dependencies, architecture, the reasons for each choice, accumulated constraints.
- A view on wikis or detailed documentation that stays up to date, with doubts that documenting everything by hand is the best approach or is needed.
- Anticipating consequences of a change before coding; preserving coherence.
- Exploration of tools such as CodeGraph to understand the relations between elements.
- A decision on structure: extend Forge, or build a separate system with its own repository and responsibilities.

### What Forge v3 already provides

- `forge-rules` adoption mode: baseline scan and the existing-project protocol (detects real conventions before writing rules).
- A hash-bound review model, sealed state and drift detection, reusable for knowledge that must not go stale silently.
- Decision and lesson logs (`forge-memory`), where a recovered rationale can live.
- The `landscape` phase, whose idea (look at what exists before deciding) has a codebase equivalent.

### Study notes (hypotheses, not decisions)

1. **Two kinds of knowledge need two methods.**
   - *Structural facts* (modules, call and dependency graph, entry points, routes, data model, tests that cover each part) can be extracted by tools. CodeGraph is named by the owner; what it provides must be verified, and other static-analysis and code-graph tools compared.
   - *Reasons* (why a strange choice exists) cannot be derived from code. Sources: version history and commit messages, linked issues and pull requests, comments, tests that pin a behavior, existing decision records, and questions put to the people who know. A reason that no source supports is recorded as `unknown`, never invented.
2. **A generated knowledge base anchored to the code, not a hand-written wiki.** Each claim cites the files and lines it rests on, with their hash. When those files change, the claim is reported stale by the CLI, the same way an approved deliverable drifts today. This answers the doubt about manual documentation: nothing is maintained by hand, and nothing silently rots.
3. **A constraints register.** Each entry: the odd element, the evidence, its status (`verified`, `inferred`, `unknown`), and the owner who confirmed it. The agent treats an unexplained element as a fence to leave in place until someone explains it.
4. **Impact analysis before coding.** For each requested feature, a deliverable lists the symbols to touch, their dependents from the graph, the tests that cover them, the constraints that apply, and the regression risks. It is reviewed by `forge-qa` and `forge-redteam` like any other deliverable.
5. **Characterization tests first** where coverage is missing, so that a change that breaks existing behavior is visible.
6. **Phase shape.** The PRD becomes a delta PRD (new requirements with IDs that reference existing behavior), architecture becomes a change design inside the existing system, and slices are scoped to the changed areas.

### Structure question: extend Forge or a separate system

| | Extend Forge with a `mode` (greenfield, feature, transform) | Separate repository |
|---|---|---|
| For | Reuses the CLI, state, gates, review, memory, rules and installer; one workflow to learn | The analysis engine can be useful alone, on its own release cycle, usable without Forge |
| Against | Grows a system whose main risk is already size and drift; phases differ per mode, which multiplies cases to test | Duplicates infrastructure, or depends on Forge anyway; two things to keep consistent |
| Leaning | A split along a seam: Forge owns the workflow and gates, a separate analysis component produces the knowledge base and the impact report. Decide after the audit and after seeing what the analysis tools provide | |

### Questions to answer

- What do the candidate tools extract, for which languages, at what cost on a large repository, and with what output format Forge can consume?
- How is the knowledge base stored (in the repository, or outside), and who is allowed to edit it?
- How does the staleness check run without re-analysing the whole project?
- What is the smallest useful version (for example: graph extraction plus the constraints register plus the impact report)?
- How are secrets and proprietary code handled when a client project is analysed?

### Expected output of the study

A design note covering the structure decision, the knowledge-base format, the staleness mechanism, the phase changes, and a test scenario on a real small project.

---

## I-003 Existing project: transform or migrate (to study, no development before a decision)

### Goal

Accompany a deep change of an existing system, for example Java to Flutter or a change of technical architecture, from analysis of the current system to preparation of the migration, without losing features or creating new problems.

### What Forge v3 already provides

The same building blocks as I-002, plus the architecture, slices, plans and test-plan phases for the target system.

### Study notes (hypotheses, not decisions)

1. **Reuse the analysis of I-002.** The source system is understood by the same engine; the migration adds what comes after.
2. **Feature inventory with evidence.** Every behavior of the source (screens, endpoints, jobs, rules, edge cases, data) is listed with the code that shows it. This is the migration equivalent of the PRD and has stable IDs.
3. **Parity matrix.** Each source behavior maps to a target slice and to a test that proves parity. Forge's existing coverage check generalises: a source behavior served by no target slice is reported.
4. **Behavior capture.** Characterization tests or recorded data (golden data) from the source system become the acceptance tests of the target.
5. **Data migration plan.** Schema mapping, volumes, transformation rules, verification queries, rollback.
6. **Migration strategy.** Incremental replacement versus full cutover, with coexistence period and rollback conditions recorded as decisions.
7. **Risk register.** Features that cannot be reproduced one to one, platform gaps, and the decisions the client must take.

### Questions to answer

- Which deliverables are new (`feature-inventory`, `parity-matrix`, `migration-plan`) and in which phases do they sit?
- How does parity testing run when the source system has no tests?
- How are non-functional behaviors (performance, offline, security) captured and compared?
- Where does the owner's wish to answer as a service provider (client mode) fit: the client confirms the parity decisions.

### Expected output of the study

A design note, the new deliverables and their checks, and a worked example on a small source system.

---

## I-004 Regulatory compliance from the first phases (to study; discuss before deciding)

### Goal

Forge identifies the regulations that apply to a project, anticipates the risks, and prevents missing important obligations, from the first phases on. Laws differ by country, so applicability depends on the markets each project targets; nothing is assumed to apply everywhere.

### What the owner asked for

- Compliance considered from the beginning, covering payments, subscriptions, sensitive data and other aspects of software development.
- A choice between a dedicated compliance skill and another approach.
- A way to handle the diversity of laws by target market.
- Motivating example: a recurring-payment subscription that users cannot cancel easily can breach the law in some places, such as California, and lead to fines. The exact legal basis has to be checked from primary sources; it is not asserted here.

### What Forge v3 already provides

- Stable requirement IDs with a coverage check from requirement to slice, and from requirement to test case (`forge check coverage`, `forge check plans`). Legal obligations can ride on this mechanism.
- A landscape phase that already researches what exists.
- Two reviewers per deliverable; the red team is well placed to challenge applicability decisions.
- Decision records, which can hold "this law applies / does not apply, decided by X".

### Study notes (hypotheses, not decisions)

1. **It is an input to the PRD, not a late review.** Obligations must exist before requirements are written, otherwise they arrive as rework. Candidate position: a phase `compliance` between `landscape` and `prd`, with mandatory re-checks when scope changes (new payment or data feature at PRD, data residency and retention at architecture, final check at validation).
2. **Forge does not give legal advice.** The output is a register for a qualified lawyer, with disclaimers. Items that are high risk or uncertain are flagged `needs legal review` and block approval until the owner records who reviewed them.
3. **A register, one row per obligation**: jurisdiction, trigger condition (when it applies), obligation in plain words, primary source (statute or regulator page) with the date it was retrieved, applicability (`applies`, `does not apply`, `unknown`) with the reason and who decided, requirement IDs it generates, and the tests that prove it.
4. **Applicability is conditional.** The same project has different obligations per market. The register is built from the questions asked at bootstrap: target countries, user types (consumers, businesses, minors), data collected, payments and subscriptions, sector (finance, health, education), and processors used.
5. **Sources and freshness.** Only primary or regulator sources are accepted; each row carries `last_verified`, and the CLI warns when a row is older than a limit set by the owner. Laws change, and research done today expires.
6. **Traceability reuses existing machinery.** A new requirement class (for example `L<n>`) is covered by slices and by test cases the same way B, E and V are. An applicable obligation with no slice or no test is reported by the CLI.
7. **Agent and skill.** A `forge-compliance` skill and a producer agent; `forge-qa` checks what is missing (markets and data types not covered), `forge-redteam` challenges every `does not apply` decision.
8. **Examples to verify, not to rely on.** For the Togo banking demo the research should look at: the Togolese personal-data protection law and its authority, the payment and e-money rules issued by the regional central bank for the West African monetary union, and anti-money-laundering and know-your-customer obligations. Whether and how each applies is part of the study.

### Questions to answer

- Separate phase or part of `landscape`? What stops it from becoming a checkbox exercise?
- How are countries and sectors selected so the register stays proportionate for a small project?
- Which obligations can be tested mechanically (for example "a subscription can be cancelled in the same number of steps as it was started") and which stay manual?
- How much of the result is shown to a client in client mode, and how do we phrase the legal-review disclaimer?

### Expected output of the study

A design note fixing the phase position, the register format, the requirement class and checks, the agent contract, and a test on the banking demo.

---

## I-005 End-to-end test: Togo mobile banking demo (planned, not started)

### Goal

Validate Forge on a real case from the initial request to the end of the preparation phases, without writing application code, and confirm that every step runs in the right order.

### What the owner asked for

- A mobile banking demo for banks in Togo, to show what is possible and win a market. It lets users interact with their accounts, see their balance, and use the usual features seen in banking apps on the Play Store.
- Backend-agnostic, because the banks' systems are unknown.
- Flutter, with GoRouter for navigation and Riverpod for state; Dio for HTTP is acceptable. Other choices are made during the process.
- Client mode, as if answering a real bank's request.
- Stop before implementation; then run the necessary tests on the system itself.

### Study notes

1. **Run in an environment that has real sub-agents.** The rule that reviews come from separate agents (R8) cannot be satisfied where no sub-agent tool exists, so the test belongs in Claude Code or OpenCode. Running the phases in a plain chat would test the CLI and skill text, not the review separation.
2. **Backend-agnostic design needs a contract layer.** The architecture phase should produce an API contract and an adapter boundary so a bank can plug its own backend; a mock server serves the demo. Whether the contract format is OpenAPI or another is a decision for the architecture phase.
3. **Include compliance.** The test is more convincing if I-004 exists, since banking is regulated. If I-004 is not ready, record the gap as a finding of the test.
4. **Success criteria to define before starting**: every phase reached in order; each deliverable has two current reviews; gates refuse a deliberately skipped step (scripted scenarios); the rules phase passes the audit on a Flutter project; client-mode touchpoints are limited to those listed; the progress report is understandable; time and size of each deliverable are recorded.
5. **Output of the test**: a findings list, fed back into the improvements list, and the demo's preparation documents (PRD, design, architecture, plans), which the owner can reuse in the presentation to the banks.

### Open questions

- Which banks and which feature set count as "usual"; who plays the client's answers?
- Language of the deliverables (the project language is set at init).
- Does the demo need a visual prototype beyond screen specifications?

---

## I-006 Full audit of the system and the repository (first pass done, see `docs/AUDIT-2026-10-19.md`)

### Goal

An exhaustive end-to-end audit of files, instructions, agents, modules, references and execution order, to find redundancy, inconsistency, dead or ambiguous instructions, escape hatches, unreferenced elements, badly positioned steps, and places that need reinforcement.

### What the owner asked for

- Redundancies, incoherences, dead or ambiguous instructions.
- Escape hatches that let the model skip rules.
- Existing elements referenced nowhere (reference files, agents that should be used).
- A check of execution order for every component, including Forge, Forge Rules and the others. Example: the benchmark must come before the PRD. Look for other mis-positioned steps or modules.
- Everything that needs reinforcement, and a coherent whole without gaps, contradictions or breaks in the process.

### Suspected holes before the first pass (outcome in the audit report)

| # | Suspicion | Basis |
|---|---|---|
| 1 | The `bootstrap` phase has no producing skill: `contract` and `conventions` are required deliverables, but the phase-to-skill mapping in the `forge` skill does not list bootstrap | Read the mapping line of the `forge` skill |
| 2 | `forge-client-liaison` is described but nothing in the CLI requires its review of client-facing documents | No reference to it in `cli/forge.py` |
| 3 | `forge-memory` is only reached through rule R7; the hooks' installation is checked by `forge hooks status` but nothing in `status` or the gates requires it | CLI and skills text |
| 4 | The v2 design-system contrast check was not ported | Port list in the status file |
| 5 | `forge-analyst`, `forge-designer`, `forge-builder` are referenced from skill text only, with no mechanical trace that they were used | Same pattern as the v2 agents |
| 6 | The first manifest (`FORGE-MANIFEST.md`) describes nine phases and eight agents with older names | Phase `rules` and agent names changed afterwards |
| 7 | Some deliverables in `REQUIRED` have no template (`contract`, `conventions`, `design-system`, `references`) | Skills list templates for other deliverables only |
| 8 | Reference files in `forge-rules` that no procedure step cites | To compute by a reference scan |

### Method

1. Build a reference graph: every skill, agent, reference file and CLI command, with who cites whom; report orphans and dangling references.
2. Walk every phase end to end as an agent would, from `forge status`, listing each instruction and the check that enforces it.
3. Compare phase order against dependencies of the deliverables (what each phase reads versus what exists by then).
4. Run the wording lint, the ten rule-set checks and all seven test suites; add adversarial scenarios for each hole found.
5. Produce a findings list with severity, a fix per finding, and tests.

---

## Other improvements to study

None recorded yet. Add each new item below with the same structure: goal, request, existing building blocks, questions, expected output.
