---
name: forge-build
description: Forge phases 7 and 8. Implements slices one at a time with tests first, tracks slice completion with evidence, then validates the finished product against the test plan. Use when forge status shows phase build or validation, or when the user asks to implement, code, build or validate the project.
---

# Forge Build

Producer agent: `forge-builder`. Reviewers: `forge-qa` and `forge-redteam`.

## Phase 7: build (no deliverable file; the gate needs every slice done)

For each slice in the order of `.forge/plans/index.md`:

1. `forge slice start <Sxx>`. One slice runs at a time. Read the rule files listed in `.forge/rules-report.md` before the first line of code.
2. Read the plan. Write the failing tests for its `TC-` lines first.
3. Implement the tasks in order. Tick each task in the plan file by changing `[ ]` to `[x]`.
4. Run the slice tests and the regression set from the test plan.
5. `forge slice done <Sxx> --evidence "<command> : <result>"` (the CLI refuses any other shape). The evidence is the real command and its real output summary.
6. Run `forge memory checkpoint` before committing.

## Phase 8: validation (deliverable `validation-report`, `.forge/validation-report.md`)

1. Run the full test plan. Write `.forge/validation-report.md` from `references/validation-report-template.md`, one row per test case with its result.
2. List every deviation from the plans and the PRD, with its decision entry.
3. Register the report, run the reviews, then the gate. Client mode: this phase is a touchpoint; show the client a plain-language acceptance summary.

## Rules

- **B1 Tests first.** A slice marked done without tests written before the code is a violation the reviewers report as `critical`.
- **B2 Plan is the contract.** Build what the plan says. When the plan is wrong, stop (R9), tell the user, and use `forge phase reopen plans --reason ...` after the user agrees. In client mode, record the deviation with `forge client ask --kind deviation ...` and wait for the answer or its stated default. Never edit an approved plan to match the code.
- **B3 No scope growth.** A feature absent from the PRD is not built. Propose it to the user; it enters through `forge phase reopen prd`.
- **B4 Evidence is real.** `slice done` carries the actual test command and its result. A claim with no command is refused by the reviewers.
- **B6 Rules are the contract.** The commands of the project's `quality-gates.md` are the commands you run before `forge slice done`, and the evidence names them. A change to a rule file goes through `forge phase reopen rules`.
- **B5 Layout regions are built.** Every `LAY-x/region` token in a plan has a matching element in the code when its slice is done.
