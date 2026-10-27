# Forge diagnostic: synthesis

Date: 2026-10-26. Baseline: `ship-clean-skills` at `main`, cloned read-only outside the
repository. This file reconciles five independent diagnostics listed at the end.

## How this was produced, and why it differs from five opinions

The five agents were not asked to "analyse Forge". They were given a partition by
artefact, a shared output contract, and an obligation to label every claim. That
mattered: without it, two agents report the same defect under different names and a
third calls a working guard a bug.

- **Fact base first.** v2 was cloned locally and both trees were inventoried before any
  judgement. v2 has no phase-template folder: its requirements live in a 1289-line
  `SKILL.md` and eleven agent files. An agent comparing `prd-template.md` (18 lines) to
  "nothing" would have invented a regression that does not exist.
- **Partition by artefact, not theme.** Templates, phases, parity and tracker do not
  own the same files, so their findings compose instead of colliding.
- **Shared output contract.** Every finding carries `path:line` and a status of
  `verified`, `inferred` or `hypothesis`.
- **A "Rejected candidates" section in every file.** Each agent had to name what it
  suspected and dismissed. This is what kept false problems out of this synthesis.
- **Adjudication by execution, not by consensus.** Every P0 below was re-checked
  against the code or run.

Two of the five files contain formatting pollution (a pasted template body in
`02-templates.md`, a duplicated example block in `05-work-tracker.md`). The findings are
sound; the files need a cleanup pass before they are quoted.

## Status definitions

| Label | Meaning |
|---|---|
| `verified-code` | Read in `cli/forge.py` or a skill file, line cited |
| `verified-run` | Reproduced with a command, output captured below |
| `inferred` | Follows from verified facts but no single line proves it |
| `hypothesis` | Plausible, unproven, needs a live project to settle |

## P0 — the workflow breaks, or a gate can be passed without doing the work

### P0-1 Ticking a plan task makes the validation phase unreachable

`verified-run`. `forge-build/SKILL.md` step 3 instructs the builder to change `[ ]` to
`[x]` in the plan file. Plans are registered deliverables with a hash. Ticking one
changes the hash, and `drift()` reports it for the already-approved `plans` phase, so
`cmd_phase_start` refuses.

Reproduction, captured verbatim:

```
registered plan at hash d7be4bf36f07
--- build ticks the task, as forge-build instructs ---
DRIFT: plan:S01: changed after its phase was approved. ...
--- now try to leave plans and start validation ---
forge: approved work drifted: plan:S01: changed after its phase was approved. Reopen the phase or restore the files
exit=1
```

Every project that follows the documentation hits this after the last slice. The only
documented exit is `phase reopen plans`, which restarts a completed phase. No suite
covers it because no suite ticks a plan.

Fix: the plan hash must ignore task checkboxes (normalise `- [ ]`/`- [x]` before
hashing), or task state must leave the plan file. A regression case belongs in
`tests/flow.sh`.

### P0-2 The validation gate never reads the validation report

`verified-code`. `gate_problems("validation")` checks that `validation-report` exists,
matches its hash and carries two reviews. It never compares the report to
`test-plan.md`, to the `TC-` cases, to the applicable obligations or to the slices. A
report containing one line passes.

Same blindness on the producer side: `forge-builder` writes both the code and the report
(`03-phases-skills.md` F4). The defect is not that `build` and `validation` share a
skill — it is that the only check on the verdict is written by the party being judged.

Fix: validation must fail on a `TC-` case absent from the report, a slice `done` with no
evidence, or an applicable `OB` with no corresponding `L<n>` result.

### P0-3 `phase reopen` leaves downstream work marked done

`verified-code`, `cli/forge.py:889-907`. Reopen resets later phases and their review
sets. It does not reset `s["slices"]`, `compliance.rechecks`, downstream
`client.reviews`, or `stuck`/`attempts`. Reopening `plans` or `architecture` therefore
leaves slices `done` from the discarded design, and the build gate — which reads
`s["slices"]` and nothing else (`:482`) — passes without rework.

Fix: clear the four on reopen, scoped to the phases after the reopened index. Add the
case to `tests/flow.sh`.

### P0-4 A deliverable registers with one `x` per empty heading

`verified-run`. `structure_problems()` checks that each `HEADINGS` entry is present and
that its body is non-empty. Nothing else. A copy of `prd-template.md` with a single `x`
under each of its four empty headings registers:

```
added one character under each of the four empty headings
registered prd hash=553a88b41410820e
exit=0
```

Two compounding facts: the placeholder ban covers `<fill>`, `{{TOKEN}}`, `TODO` and
`TBD` but not `<rule>`/`<constraint>`, and six required deliverables have no `HEADINGS`
entry at all — `screen-map`, `layouts`, `slices`, `plans-index`, `plan:<Sxx>`,
`screen:<id>` — so `forge template` refuses to print them and registration checks
nothing (`HEADINGS.get(name, [])`).

Aggregate from `02-templates.md`: of 86 template sections, 15 are checked, 48 are
unchecked prose, 23 are vacuous.

Fix: a section is satisfied by a minimum body shape per deliverable (an ID row, a table
with N columns, a link to a source), not by non-empty text. Add the six missing
`HEADINGS` entries.

### P0-5 Nothing runs the 14 suites on push

`verified-code`. No `.github/`, no `package.json`, no CI. `README.md:52` still tells a
human to run "all thirteen" and omits `i18n.sh`. A regression introduced today is
detected only if someone remembers to run a POSIX-only suite by hand on a machine that
has bash.

This is P0 because it is why P0-1 through P0-4 are still live, and why the counts in
`README.md` and `docs/STATUS.md` have drifted twice.

Fix: a workflow running `for t in tests/*.sh` on Ubuntu, plus the repository validator
below.

## P1 — deliverables are structurally accepted and substantively empty

| # | Finding | Evidence | Why it matters |
|---|---|---|---|
| P1-1 | Templates are skeletons, not specifications | 15/86 sections checked; 48 unchecked | A weak model fills headings with prose and passes |
| P1-2 | `prd-template.md` omits personas, stories with acceptance, NFRs, metrics with a baseline, risks, glossary, release mapping | `02-templates.md` "The PRD" | The PRD is the input of every later phase |
| P1-3 | `architecture-template.md`: 10 sections, 4 empty, 0 parsed | `02-templates.md` F5 | Coverage is proved only through `slices.md` |
| P1-4 | `design-system.md` is required, 13 lines, read by nothing | `02-templates.md` F4 | The design phase has no enforced design system |
| P1-5 | Reviewers lost their per-document checklists; the design checklist has no carrier | `04-v2-parity.md` F4, `03-phases-skills.md` F9 | Review becomes opinion |
| P1-6 | The v2 contrast and design-quality checks were not ported | `04-v2-parity.md` F5 | Accessibility and hierarchy regress silently |
| P1-7 | `slice done` validates the shape of a sentence, not a test result | `04-v2-parity.md` F11 | Evidence is a string, never a file |
| P1-8 | Every suite builds its fixture from the `<fill>` stub | `02-templates.md` F1/F7 | No suite ever registers a realistic document |

## P2 — model, ownership and lost capabilities

| # | Finding | Evidence | Note |
|---|---|---|---|
| P2-1 | No phase is bound to a skill or producer by anything the CLI checks | `03-phases-skills.md` F1 | The only mapping is prose in `skills/forge/SKILL.md:52` |
| P2-2 | Three generations of phase numbers coexist; two phases are both "phase 2" | `03-phases-skills.md` F2 | Six skill files match an older `PHASES` list |
| P2-3 | `plans` is produced by the architecture agent | `03-phases-skills.md` F6 | Reverses a documented v2 decision |
| P2-4 | The change-impact protocol was dropped; reopen is not its equivalent | `04-v2-parity.md` F3 | Reopen resets, it does not analyse impact |
| P2-5 | No dependency-cycle detection between slices | `04-v2-parity.md` F9 | v2 rejected a cycle in code |
| P2-6 | The data model is prose; no DDL is written or executed | `04-v2-parity.md` F8 | v2 ran the DDL |
| P2-7 | Scenario tests, module prioritization, the interview protocol, the archetype catalogue, the self-tests, release tooling | `04-v2-parity.md` F7/F13/F15/F16/F17 | 27 of 43 capabilities classified regressed |
| P2-8 | Human work tracker: design ready, implementation blocked | `05-work-tracker.md` | Cannot show task progress until P0-1 is fixed |

## Conflicts between agents, and how each was settled

A disagreement is not a fact. Each one was re-checked.

1. **"`forge template` prints a skeleton the CLI refuses" (templates F1, critical).**
   Downgraded to minor. `cmd_register` refusing `<fill>` is the placeholder guard
   working as designed; printing `<fill>` is how it marks what to replace. The real
   defect underneath is P1-8: the suites build every fixture from that stub.
2. **"A verbatim template copy passes the PRD phase" (templates F2, critical).**
   Confirmed, with a correction: the untouched copy fails on four empty sections. It
   passes once a single character is added to each. Reported as P0-4 with the exact
   reproduction.
3. **"`forge-discover` cannot satisfy its own gates" (phases F3).** Not adopted as a P0.
   The claim depends on a chain where compliance has not run; with the full chain the
   `L<n>`/`OB` checks are satisfiable. Left as `hypothesis` in the source file.
4. **"`one phase = one skill` is violated by `forge-discover` (3 phases) and
   `forge-build` (2)."** Partially rejected. Grouping landscape/prd/roadmap is
   justified: shared inputs, one reviewer, one reference folder. Grouping
   build/validation is not the defect either — P0-2 is: the gate cannot see the
   report's content. Splitting the skill now would add a transition and fix nothing.
   The principle holds as a *responsibility* rule, not as a file-per-phase rule.
5. **"Register the tracker as a deliverable."** Rejected on evidence: every
   regeneration clears its reviews and `drift()` makes it permanently stale, which
   blocks the next phase. The tracker is a derived view.

## What v2 got right and v3 must keep

`01-v2-baseline.md` found 31 v2 weaknesses, so this is not nostalgia. Three mechanisms
survived the comparison:

1. **Refusal is code, not prose.** v2's `state.js` rejected a dependency cycle, a
   renumbering and a premature artefact. v2's drift came from the 9 written rules with
   no executable check. v3 has the same failure mode in a different place.
2. **Execute, do not read.** v2 ran the DDL and required test *cases*, with `skipped`
   never counted as `pass`. v3 accepts a sentence.
3. **One fact, one home, enforced.** v2 captured a heading map at approval and counted
   undeclared references. v3 duplicates the phase table and copies the touchpoint set
   into eight places.

## Proposed order of correction

Order by dependency, not by severity alone: P0-5 first because it prevents recurrence,
then the two that block completion, then the two that admit empty work.

1. **CI + repository validator** (P0-5). Nothing else stays fixed without it.
2. **Plan-tick drift** (P0-1). Without it, no project reaches validation.
3. **Validation gate content checks** (P0-2).
4. **`phase reopen` completeness** (P0-3).
5. **Structural minimums + six missing `HEADINGS`** (P0-4).
6. **PRD, architecture and design-system templates** (P1-1 to P1-4).
7. **Reviewer checklists, contrast check, evidence shape** (P1-5 to P1-7).
8. **Phase registry in the CLI + one numbering** (P2-1, P2-2).
9. **Human tracker** (P2-8), after step 2.
10. **Parity backlog** (P2-3 to P2-7), one item per change with its own test.

## Open questions for the decision-maker

1. P0-1 has two shapes: normalise checkboxes before hashing the plan, or move task state
   out of the plan into `state.json`. The second is cleaner and larger.
2. Splitting `forge-build` into two skills: after P0-2, or not at all?
3. The tracker: slice-level only, or task-level detail? Task-level requires P0-1.
4. `plans` back to its own agent, or keep the architecture agent and rename the phase?

## Source diagnostics

| File | Subject | Findings |
|---|---|---|
| `01-v2-baseline.md` | v2 production method and deliverable requirements | 31 |
| `02-templates.md` | v3 templates, checked vs vacuous | 12 |
| `03-phases-skills.md` | phase chain, ownership, transitions | 11 |
| `04-v2-parity.md` | capability parity v2 to v3 | 20 |
| `05-work-tracker.md` | human progress file specification | 10 |

Reproduction of P0-1: `forge-build/SKILL.md` step 3, `drift()` at `cli/forge.py:219`,
`cmd_phase_start` refusal, captured above. Reproduction of P0-4: `structure_problems()`
at `cli/forge.py:135`, `cmd_register` at `:322`, captured above.
