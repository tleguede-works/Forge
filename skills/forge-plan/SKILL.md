---
name: forge-plan
description: Forge phase 6. Writes one implementation plan per slice and the global test plan, precise enough for a weaker model to execute without guessing. Use when forge status shows phase plans, or when the user asks for implementation plans, task breakdowns, acceptance criteria or a test plan.
---

# Forge Plan

Deliverables: `plan:<Sxx>` for every slice (`.forge/plans/<Sxx>.md`), `plans-index` (`.forge/plans/index.md`), and `test-plan` (`.forge/test-plan.md`). Write in the project language. Producer agent: `forge-architect`, because it holds the architecture. Reviewers: `forge-qa` and `forge-redteam`.

## Procedure

0. Read `.forge/rules-report.md` and the rule files it lists. Every plan follows them, and the test plan takes its gate commands from the project's `quality-gates.md`.
1. For each row of `slices.md`, write `.forge/plans/<Sxx>.md` from `references/plan-template.md`.
2. In every plan that builds a layout region, write the token `LAY-<name>/<region>` in the task that builds it. Foundation slices own these tasks.
3. Write `.forge/plans/index.md` from `references/plans-index-template.md`: one line per slice with its id, name and order of implementation.
4. Write `.forge/test-plan.md` from `references/test-plan-template.md`. Every business rule, edge case and validation (B, E, V IDs) appears in one or more test case rows, and every slice id appears.
5. Register each file. Plans register as `plan:<Sxx>`.
6. Run `forge check plans` and `forge design check --plans`. Fix every line they print.
7. Run the reviews on every plan and on the test plan, then the gate.

## Rules

- **P1 One plan per slice.** The `serves` line of a plan equals the `serves` column of `slices.md`.
- **P2 Bounded size.** A plan has 1 to 15 tasks. More means the slice is split, which reopens the architecture phase with `forge phase reopen architecture --reason ...`.
- **P3 Tasks name files.** Each task states the files it creates or edits and the observable result.
- **P4 Tests are first-class.** A plan has one or more `TC-<Sxx>-<n>` line that states the input and the expected result, and the ID it verifies.
- **P5 Written against the contract.** A plan quotes the API contracts and data model of `architecture.md`. A reviewer finds the contradiction if it does not.
- **P6 No code.** A plan describes what to build and how to verify it; it contains no implementation.
