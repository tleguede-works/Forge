# Test plan: <product name>

## Strategy {#strategy}
| Level | What it covers | Tool | Command |
|---|---|---|---|
| unit | pure logic and validations | <tool> | <command> |
| integration | modules, database, integrations | <tool> | <command> |
| end to end | one user journey per main persona | <tool> | <command> |

## Coverage matrix {#coverage-matrix}
One row per PRD requirement, linked to the slice and the test case that proves it.
| PRD ID | Slice | Test case | Level |
|---|---|---|---|
| B1 | S02 | TC-S02-1 | unit |

## Regression set {#regression-set}
The command that runs the whole regression set before every `forge slice done`, and the
output that counts as a pass. A skipped test is not a pass.
- command: <command>
- pass condition: <what the output must show>

## Environments and data {#environments-and-data}
| Environment | URL or host | Data | Reset procedure |
|---|---|---|---|
| <environment> | <URL> | <fixtures or seed> | <command> |
