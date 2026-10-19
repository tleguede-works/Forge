---
name: forge-rules
description: Generates, consolidates or audits the AI coding-agent rule set of a project - an entry file (AGENTS.md or CLAUDE.md) plus scoped rule files, wired into OpenCode, Claude Code or AGENTS.md alone, built from a template library selected by the detected stack. Use when forge status shows phase rules, or when the user asks for project rules, coding standards for agents, AGENTS.md, CLAUDE.md, .cursor rules, or to audit existing instruction files.
---

# Forge Rules

Produces a rule set an agent follows, not a style guide it skims. Everything it emits is checked by `forge rules audit`; a failed check is a defect to fix, never a point to discuss.

Memory (journal, decisions, lessons) belongs to `forge-memory`. This skill never writes those files and its rule files never name the Forge tool.

## Rules

- **F1 Audit is a command.** Run `forge rules audit <project> --target <opencode|claude|agents> --budget <lines>` and fix every failed check before delivery. Report its output verbatim.
- **F2 Scan first.** Run the baseline scan (`references/baseline-scan.md`) before writing any threshold. The scan decides greenfield or ratchet; you never ask the user.
- **F3 Select, never copy.** Templates in `references/templates/` are selected by `references/stack-detection.md`. Record the signal that selected each one and the row that excluded each omitted one. Never edit a template during a run.
- **F4 Sourced claims.** Every technology-specific rule names the rung of `references/documentation-sources.md` that supports it, or an entry in the decisions log. An unsourced claim becomes a question, never a hedged rule.
- **F5 One fact, one place.** A rule lives in one file. Other files reference it by file and section name.
- **F6 Gates are commands.** A threshold, a command or a banned list is a gate. Each gate names a command with a pass condition (exit 0). A gate with no command is prose, and prose is cut first when the budget is exceeded.
- **F7 Merge, never overwrite.** Wiring an existing config adds keys and keeps every existing key.
- **F8 Preserve in consolidation.** When reorganizing existing rules, remove only tutorial prose and exact duplicates. Report `N preserved, M absorbed, K lines of tutorial prose cut (listed)`.
- **F9 Contradiction with code.** When the project has code, detect its real conventions first (`references/existing-project-protocol.md`). A rule that contradicts working code is not emitted.
- **F10 No self-reference.** A generated file never names its source template, the profile it came from, or another project's files.

The six design principles behind these rules are in `references/principles.md`. Read it once per session before drafting.

## Inside Forge: the rules phase

Phase `rules` runs after `architecture` (the stack is decided) and before `plans` (the plans and the test plan quote the gate commands). Deliverable: `rules-report` (`.forge/rules-report.md`), written in the project language. Producer agent: `forge-architect`. Reviewers: `forge-qa` and `forge-redteam`.

1. Produce the rule set in the project root with the procedure below. The rule files stay in the project, outside `.forge/`.
2. Write `.forge/rules-report.md` from `references/rules-report-template.md` with these lines, in this form: `- target: opencode|claude|agents`, `- budget: <total lines>`, then the template selection with the signal behind each choice, the baseline status of each gate, and the verbatim output of `forge rules audit`.
3. Register it, run both reviews, then `forge gate check`. The gate runs the same audit with the target and budget of the report and lists every failed check. Fix the rule files, not the report.
4. On approval the CLI records a hash of the entry file (outside the Forge block) and of every rule file. A later edit to any of them is reported as `DRIFT` and blocks the next phase start until `forge phase reopen rules --reason ...` and a new gate.

An existing project (adoption mode) uses the same phase; its baseline scan feeds the report.

## Procedure

Detailed steps are in `references/workflow.md`. Order:

1. **Scan** (F2). Write `docs/quality-baseline.md`.
2. **Probe and ask**: stack from the scan; ask only the target format, the git strategy, decisions the code cannot answer, monorepo scope. The user's stated structure is the specification.
3. **Verify** against real sources (F4).
4. **Choose the mode**: bootstrap, consolidation or adoption (`references/existing-project-protocol.md`).
5. **Measure the set** before drafting: the budget for the chosen target is in `references/target-formats.md`. A target without scoping loads every file every session, so splitting a file saves nothing.
6. **Draft** from the selected templates and `references/rule-file-template.md`.
7. **Audit**: `forge rules audit` (F1), then the judgement half of `references/audit-checklist.md`. Do not report a judgement item as verified when it was not checked.
8. **Wire and deliver** (F7). Verify that the config parses and every path it names exists. A glob that matches nothing is valid and loads nothing.
9. **Read-back test**: from a cold session, the agent must state its build command, its definition of done and which rule files govern a given area. If it cannot, fix the wiring before adding content.

## When a template was wrong

Fix the template file in the Forge repository, not only the delivered output. The next project copies the template.

## Reference map

| Need | File |
|---|---|
| Why the rules are shaped this way | `references/principles.md`, `references/research-summary.md` |
| Detect stack and pick templates | `references/stack-detection.md` |
| Target formats and budgets | `references/target-formats.md`, `references/mdc-frontmatter-spec.md` |
| Scan and mode | `references/baseline-scan.md` |
| Existing code or rules | `references/existing-project-protocol.md` |
| Source ladder | `references/documentation-sources.md` |
| Monorepo | `references/monorepo-strategy.md` |
| Architecture choices | `references/architecture-decision-guide.md` |
| Rule file shape | `references/rule-file-template.md` |
| Audit checklist | `references/audit-checklist.md` |
| Past failures, read when consolidating or porting | `references/postmortems.md` |
