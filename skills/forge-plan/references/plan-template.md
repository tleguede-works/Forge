# <Sxx> <Slice name>

## Serves {#serves}
- serves: B1,B2,E1

## Contract {#contract}
The inputs, outputs, errors and data this slice touches, copied from `architecture.md`
(section 5 and 6). Any difference from the architecture is a decision, not a silent edit.

## Tasks {#tasks}
One to fifteen tasks, in execution order. A task names the files it creates or edits and
the observable result. A task that builds a layout region carries the token `LAY-x/region`.
- [ ] T1 <what> | files: <paths> | result: <observable outcome>
- [ ] T2 <what> | files: <paths> | result: <observable outcome>

## Acceptance {#acceptance}
Numbered criteria, each observable and each tied to a PRD ID. A criterion a human cannot
check without reading the code is not a criterion.
1. <criterion> (B1)

## Test cases {#test-cases}
One line per case. `input` and `expected` are concrete values, not descriptions.
- TC-<Sxx>-1 | verifies B1 | input: <values> | expected: <observable result>
