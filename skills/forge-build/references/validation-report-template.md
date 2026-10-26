# Validation report: <project name>

## 1. Test plan results {#test-plan-results}
One row per `TC-` case of the plans and of the test plan. No row is missing: the gate
compares this table with the test cases the plans define. `result` is `pass`, `fail` or
`blocked`. `evidence` is the command output or the file that holds it.
| test case | verifies | command | result | evidence |
|---|---|---|---|---|
| TC-S01-1 | B1 | <command> | pass | <what it printed> |

## 2. Deviations from the plans and the PRD {#deviations-from-the-plans-and-the-prd}
One line per deviation, with its `D-<n>` decision. Write `None; no deviation was found` when there is none.
- <deviation>: <decision entry>

## 3. Requirements not met {#requirements-not-met}
Each with its ID, the reason, and the proposal. Write `None; every requirement is met` when there is none.
- <B/E/V/C/L id>: <reason>

## 4. Acceptance summary {#acceptance-summary}
Plain language, for the client touchpoint: what was built, what was verified, what remains
uncertain, and the decision the client is asked to take.
