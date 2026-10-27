# Parity backlog: v2 capabilities v3 has not ported

`docs/MIGRATION-v2.md` records what v2 had. This file holds the capabilities v3 still
lacks, why each one matters, and the test that would prove it is done. Nothing here is a
defect of the current gates: every item is a capability, not a shortcut. An item leaves
this file only when it ships with its test.

Read `docs/archive/diagnostics/04-v2-parity.md` for the evidence behind each row.

## Closed by the 2026-10 correction

| Item | What closed it | Test |
|---|---|---|
| P0-1 plan ticks blocked validation | `art_hash` ignores task checkboxes | `tests/validation.sh` |
| P0-2 the validation gate ignored its report | `validation_problems` compares the report with the plans | `tests/validation.sh` |
| P0-3 reopen left slices done | `cmd_reopen` resets the subtree | `tests/validation.sh` |
| P0-4 one `x` per section registered | `MIN_BODY`, `ROW_RULES`, template-token refusal | `tests/validation.sh`, `tests/templates.sh` |
| P0-5 nothing ran the suites on push | `.github/workflows/ci.yml` | CI |
| P2-1 no executable phase/skill mapping | `PHASE_SKILL`, `PHASE_PRODUCER`, `forge status` prints both | `tests/progress.sh`, `scripts/validate_repo.py` |
| P2-2 three generations of phase numbers | phase numbers removed from every skill; phases are named | `scripts/validate_repo.py` |
| P2-8 human work tracker | `forge progress`, `.forge/progress.md` | `tests/progress.sh` |

## Open

### B-1 Change-impact protocol (P2-4)

v2 asked, for every approved change, which requirements, screens, slices and tests it
touches, and refused the reopen until the answer was recorded. v3 `phase reopen` resets
the subtree and stops there: the agent redoes the work but writes no impact analysis, so
a change can silently drop a requirement that no later deliverable mentions.

Fix: `forge phase reopen --reason ...` takes `--impact <ids>` (the requirement and
deliverable IDs the change touches) or `--no-impact "<why>"`, records it in
`decisions.md`, and the gate of the reopened phase refuses a requirement that was live
before the reopen and is now neither live nor withdrawn with a reason.

Test: a `tests/flow.sh` case that reopens the PRD with an impact list, then proves that a
requirement dropped without an out-of-scope line fails, and that the same change with the
line passes.

### B-2 Slice dependency cycles (P2-5)

`plans-index` carries a `depends on` column that nothing parses. A cycle (S01 → S02 →
S01) makes every slice unschedulable, and the build phase discovers it one slice at a time.

Fix: `forge check plans` parses the column, refuses an unknown slice ID, refuses a cycle,
and refuses a `depends on` that names a later order.

Test: `tests/flow.sh` builds a three-slice index with a cycle and expects the refusal by
name.

### B-3 Executed data model (P2-6)

v2 wrote the schema as DDL and executed it against a throwaway database, so a wrong type
or a missing foreign key failed before any code was written. v3 keeps the data model as a
Markdown table, and the plans phase can only trust it.

Fix: the architecture template gains a fenced `sql` block per entity; `forge check schema`
extracts the blocks, runs them in an in-memory SQLite database (stdlib) and refuses a
syntax error, a table with no primary key, or a foreign key that names no table.

Test: `tests/validation.sh` feeds a valid schema and three broken ones.

### B-4 Scenario tests (P2-7)

v2 turned each user story into a scenario (given / when / then) that the test plan had to
cover. v3's test plan covers requirement IDs, not journeys, so a product can satisfy every
`B` ID and still fail the user's actual path.

Fix: the PRD user-story table gains a `scenario` column with `Given ... When ... Then ...`
in one cell; `forge check plans` requires every scenario to appear in the coverage matrix.

Test: a plan set that covers every ID but no scenario is refused.

### B-5 Module prioritization (P2-7)

v2 ranked modules by how often users reach them and used that rank to order slices. v3
states "its rank follows how often users reach it" in the architect skill and checks
nothing, so the order is a judgement no reviewer can audit.

Fix: the slice rows gain a `reach` column (a number or `foundation`), and
`forge check coverage` refuses a slice ordered before a slice with a strictly higher
reach in the same release.

Test: `tests/flow.sh` with two inverted rows.

### B-6 Interview protocol (P2-7)

v2 had a fixed interview: the questions to ask, in which order, with which fallback when
the user does not know. v3 leaves the interview to the model, so a weak model asks a
different set every run and misses the facts the later phases need (markets, minors,
payments, data).

Fix: `skills/forge-discover/references/interview.md` holds the ordered question list with
the "the user does not know" fallback; `forge bootstrap check` refuses a brief whose
required facts are empty or marked unknown without an open question and an owner.

Test: a brief with an empty `payments` row and no open question is refused.

### B-7 Archetype catalogue (P2-7)

v2 named the archetype from a catalogue (marketplace, CRUD back office, booking, social
feed, workflow, dashboard) and derived the invariant feature set from it. v3 asks for an
archetype with no reference, so the answer is a word nobody can check.

Fix: `skills/forge-discover/references/archetypes.md` lists the archetypes, their
invariant features and their typical screens; the landscape checklist requires the
archetype to be one of them or to say why none fits.

Test: a review checklist entry, not a CLI check: the file must exist and be named by the
skill, which `scripts/validate_repo.py` already enforces.

### B-8 Self-tests (P2-7)

v2 shipped a `forge selftest` that ran its own scenarios inside a temporary project and
reported a pass list. v3 relies on the bash suites, which need a POSIX shell, so a Windows
user cannot verify an installation at all.

Fix: port `tests/e2e.sh` to a Python `forge selftest` that creates a temporary project,
drives the CLI and prints one line per check, with the same cases.

Test: `forge selftest` returns 0 on a clean install and 1 when a fixture is broken.

### B-9 Release tooling (P2-7)

v2 had a version, a changelog and an upgrade path that migrated `.forge/state.json`
between versions. v3 has `VERSION = 3` and no upgrade: an installed kit from an earlier
v3 build is only detected, never migrated.

Fix: `forge upgrade --from <version>` rewrites the state, and `forge status` names the
migration it needs.

Test: a state file with the previous schema is migrated and its phases survive.

### B-10 Plans owned by the architecture agent (P2-3)

`PHASE_PRODUCER` maps `plans` to `forge-architect`, which reverses a v2 decision: a plan
written by the author of the architecture inherits its blind spots, and the reviewer who
must catch them is reviewing the same mind. This is not a bug the CLI can detect.

Options: a `forge-planner` agent that reads the architecture as a contract, or an explicit
decision entry that keeps the current mapping and states why. The second option is
acceptable only with the reason recorded in `decisions.md`; until then this row is open.

Test: whichever option is chosen, `scripts/validate_repo.py` already proves the named
producer exists; the review checklist gains the item "the plan contradicts the
architecture nowhere it was not allowed to".
