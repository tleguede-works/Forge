# Human work tracker: specification

## Scope and method

Design only. No existing file in this repository is modified, and no `forge init` was run in a project. The one file written is this one.

**Read for this study**

| Source | What it settled |
|---|---|
| `cli/forge.py` (`cmd_slice` 858-886, `gate_problems` 453-508, `drift` 219-230, `next_action` 252-294, `cmd_register` 322-350, `write_now` 552-559, `parse_slices` 766-775, `plans_problems` 813-845, `cmd_client_report` 1271-1296, `op_key` 1409-1431, `record_attempt` 1449-1467) | What is stored, what is only printed, what refuses what |
| `skills/forge-plan/{SKILL.md,references/plan-template.md,plans-index-template.md}`, `skills/forge-architect/references/slices-format.md`, `skills/forge-build/SKILL.md`, `skills/forge/SKILL.md`, `skills/forge-memory/SKILL.md` | The only stated owners of order, tasks, acceptance, evidence |
| `docs/archive/LOOPS.md`, `docs/ESCAPE-HATCH-AUDIT.md`, `docs/STATUS.md`, `tests/flow.sh`, `tests/e2e.sh`, `tests/i18n.sh` | Which failures are already named, which are tested |
| v2 clone: `skills/forge/SKILL.md`, `scripts/state.js`, `scripts/lib/forge-lib.js`, `references/state-schema.md`, `skills/project-rules-architect/templates/memory/*` | The precedent: what was tried, what broke |

**Executed** (Python 3.12, `python`, in `%TEMP%\forge-audit-05\`, outside this repository; a `.forge` was built by importing the CLI and calling `forge.save`, not by `forge init`):

```
B after done    slices = {"S01": "done"}
C evidence in state.json? False
D journal line  = - 2026-10-26T09:00:30Z | slice_done | S01 evidence='pytest tests/test_pay.py : 4 passed'
E gate build    = ['slice S02 is pending, not done']
F drift         = [('plan:S01', 'plan:S01: changed after its phase was approved')]
G phase start validation -> exit 1
with 5 columns: [('S01', 'Pay', 'billing', {'B1'}), ('S02', 'Refund', 'billing', {'B2'})]
```

**Not executed**: the 14 POSIX suites (`AGENTS.md` I6: `python3` is the Store stub here and no POSIX shell exists), and any v3 lab through `validation`. Claims resting only on the code path are labelled `inferred`.

Labels used below: `verified` = read in the source or reproduced by the run above; `inferred` = follows from a code path I did not execute; `hypothesis` = a prediction about human or model behaviour.

## What data exists when the tracker is generated

The tracker exists from the moment `plans` is approved (`cli/forge.py:8-9` orders `plans` before `build`). At that instant, for each slice row:

| Fact | Owner today | Shape | Read by the CLI? |
|---|---|---|---|
| Slice id, name, module, served IDs | `.forge/slices.md` | `\| S01 \| … \| module \| B1,B2 \|` (`slices-format.md:3`) | yes, `parse_slices` (`cli/forge.py:766-775`), first 4 cells only |
| Order of implementation | `.forge/plans/index.md` `Order` column (`plans-index-template.md:3-5`) | free text | only "the id appears somewhere" (`cli/forge.py:834-837`) |
| Release (MVP, R1, R2) | `.forge/plans/index.md` `Release` column | free text | no |
| Slice status | `state.json` → `s["slices"]` | `pending` / `in_progress` / `done` (`cli/forge.py:865-885`) | yes |
| Completion evidence | `.forge/memory/journal.md` only | `- <ISO> \| slice_done \| S01 evidence='<command> : <result>'` (`cli/forge.py:884`, format at 173-175) | no |
| Tasks and their ticks | `.forge/plans/<Sxx>.md` `## Tasks` | `- [ ] T1 … \| files: … \| result: …` | counted, not listed (`cli/forge.py:825`) |
| Acceptance criteria | `.forge/plans/<Sxx>.md` `## Acceptance` | numbered prose, each tied to an ID (`plan-template.md:13-14`) | no |
| Test cases | `.forge/plans/<Sxx>.md` `## Test cases` | `- TC-S01-1 \| verifies B1 \| input: … \| expected: …` | counted (`cli/forge.py:832`) |
| Current position and next action | computed | `next_action(s, r)` (`cli/forge.py:252-294`) | printed only |

What does **not** exist at that moment, and constrains the four questions:

1. **No evidence in `state.json`.** Run `C` above. The evidence string is journaled, not stored, and it is journaled with `!r`, so the file holds `evidence='…'` or `evidence="…"` when the text contains a quote (`cli/forge.py:884`). A renderer that reads only `state.json` cannot answer question 3.
2. **No per-slice "validated".** v3 keeps three slice states. `.forge/validation-report.md` is per test case (`validation-report-template.md:3-5`), not per slice, and it is a `validation` deliverable that does not exist during build (`REQUIRED["validation"]`, `cli/forge.py:21`). Question 3 therefore has two different answers before and after validation, and the word "validated" cannot be read off the state.
3. **No task status outside the plan file.** Ticking `[ ]` → `[x]` is the only task-level record, and `forge-build/SKILL.md:16` instructs it. See F2: doing it today drifts an approved deliverable.
4. **No effort, duration, weight or code measure.** Nothing in the state records time or size. A percentage, a Gantt bar or a velocity figure would be invented data.
5. **Slice rows survive a reopen.** `cmd_reopen` resets phases and reviews, not `s["slices"]` (`cli/forge.py:896-901`; `AGENTS.md` "Known traps" states the same). After reopening `plans` or `architecture`, old `done` values remain in state with plans under rewrite.

## Findings

### F1 — Completion evidence exists only in the journal, repr-encoded

- **Ref** `cli/forge.py:883-884`, `cli/forge.py:173-175`; run `C`, `D`
- **Status** verified
- **Severity** major
- **What** `cmd_slice` writes `s["slices"][id] = "done"` and journals the evidence; `state.json` keeps no evidence. The journal line is `- <ISO> | slice_done | S01 evidence='<command> : <result>'`, produced with `{a.evidence!r}`.
- **Evidence** `C evidence in state.json? False`; `D journal line = - 2026-10-26T09:00:30Z | slice_done | S01 evidence='pytest tests/test_pay.py : 4 passed'`.
- **Recommendation** The renderer reads `journal.md`, selects the last `slice_done` line per slice id, and decodes the repr with `ast.literal_eval` (falling back to quote stripping). Do not add an evidence field to `state.json`: `state.json` is a metadata file and the journal is already append-only and already tested (`docs/STATUS.md:15`). Document the journal as the sole home of evidence in `forge-memory/SKILL.md`, which today lists what each layer holds without naming evidence (`forge-memory/SKILL.md:10-15`).

### F2 — Ticking a plan task drifts an approved deliverable and blocks `phase start validation`

- **Ref** `skills/forge-build/SKILL.md:16` versus `cli/forge.py:219-230` and `cli/forge.py:312-314`; run `F`, `G`
- **Status** verified (executed)
- **Severity** critical
- **What** `plan:<Sxx>` is a registered deliverable of phase `plans` with a recorded hash (`cli/forge.py:23`, `340-342`). Once `plans` is approved, `drift()` reports any hash change as "changed after its phase was approved", and `cmd_phase_start` refuses the next phase while drift exists. The build skill tells the agent to change exactly those bytes.
- **Evidence** `F drift = [('plan:S01', 'plan:S01: changed after its phase was approved')]`; `G phase start validation -> exit 1`, message `approved work drifted: plan:S01`. No suite covers it: `tests/flow.sh:65-68` starts and finishes a slice, runs `gate check`, then reopens `prd`; nothing reaches `phase start validation`.
- **Recommendation** Hash plans with task boxes normalised: a `plan_sha()` that rewrites `- [x] T` to `- [ ] T` before hashing, used by `cmd_register` and `drift` for names starting `plan:`. A tick then costs nothing, and any other edit still drifts. Close it with a case in `tests/flow.sh` (tick a task, `phase start validation` succeeds) and a row in `docs/ESCAPE-HATCH-AUDIT.md` stating that only the box character is exempt. Until this ships, the tracker must not source task counts (see Content contract, "tasks"), or it will display a number whose production poisons the next phase.

### F3 — Two implementation orders, and the CLI uses the one the build skill does not name

- **Ref** `skills/forge-build/SKILL.md:12`, `skills/forge-architect/SKILL.md:22`, `cli/forge.py:289`
- **Status** verified
- **What** Build says "for each slice in the order of `.forge/plans/index.md`". The architect orders the `slices.md` rows "foundations first, then slices by roadmap release". `next_action` picks `todo[0]` from `parse_slices`, i.e. the `slices.md` order. Nothing compares the two.
- **Evidence** `cli/forge.py:289`: `todo = [x[0] for x in parse_slices(r) if s.get("slices", {}).get(x[0]) != "done"]`; `plans_problems` checks only that the index mentions each id (`cli/forge.py:837`), never the `Order` value.
- **Recommendation** One order, one home: `plans/index.md`. `next_action` reads the `Order` column, and `plans_problems` refuses an index whose order contradicts `slices.md` row order unless a decision entry records the difference. The tracker prints the index order and the CLI's next action then agrees with it by construction.

### F4 — Release is free text that no check reads

- **Ref** `plans-index-template.md:3-5`, `cli/forge.py:834-837`, `slices-format.md:3`; column probe in *Scope and method*
- **Status** verified
- **What** "4 slices across 2 releases" needs a release per slice. The only column is `Release` in `plans/index.md`, and the gate checks only that the file contains the slice id. `slices.md` has no release column, and `parse_slices` silently ignores a fifth cell.
- **Evidence** Probe output: `with 5 columns: [('S01', 'Pay', 'billing', {'B1'}), …]` — the `MVP` and `R1` cells are dropped. `cli/forge.py:773` requires `len(c) >= 4` and keeps `c[0..3]`.
- **Recommendation** Read `Release` from `plans/index.md` (already the order's home) and make `plans_problems` refuse a row whose release is empty or absent from the roadmap's `## MVP`, `## R1`, `## R2` headings (`cli/forge.py:103`). Cost: about 10 lines and one `flow.sh` case. Do not add a column to `slices.md`: it would be dead until `parse_slices` changes, and the format doc, the template and `tests/` would all move for a fact the index already holds.

### F5 — "Validated" is not a slice state in v3, and v2 had it

- **Ref** `cli/forge.py:865-885` (`pending`/`in_progress`/`done`), `validation-report-template.md:3-5`, v2 `references/state-schema.md:183`, v2 `scripts/lib/forge-lib.js:68`
- **Status** verified
- **What** v2 carried `identified → planned → in_progress → implemented → validated` per slice. v3 keeps three values and no `validated`. Before `validation` runs, "done" means "the builder ran a command and quoted it", which is not the same claim as "the test plan passed".
- **Evidence** v2 `forge-lib.js:68`: `slice: ['identified', 'planned', 'in_progress', 'implemented', 'validated']`; v2 `state-schema.md:183` repeats it as the contract. v3 `cli/forge.py:883` writes only `done`.
- **Recommendation** Keep the collapse (a fourth state would need a writer, a gate check and a reset path), and make the tracker say two different words for two different claims: **built** from `slices.done` plus a journal evidence line, **validated** only from `.forge/validation-report.md` once its `## Test plan results` table cites the slice's `TC-<Sxx>-n` ids. Record the deliberate removal in `docs/MIGRATION-v2.md` (the `Slice status` row), as `AGENTS.md` "v2 parity" requires: a capability v2 had and v3 lacks is a regression until recorded as removed on purpose.

### F6 — A registered tracker cannot be regenerated: reviews reset, drift is permanent

- **Ref** `cli/forge.py:338-347`, `cli/forge.py:219-230`, `cli/forge.py:491-507`, `cli/forge.py:312-314`
- **Status** verified (code path) + `inferred` for the end-to-end consequence
- **What** Registering the tracker in `REQUIRED` makes it a deliverable: a hash change clears its reviews, the gate demands two current reviews, and `drift()` reports the change after approval. A file rewritten at every slice change would therefore be permanently stale, permanently unreviewed, or both.
- **Evidence** `cmd_register`: `entry["reviews"] = old["reviews"]` only when `old["hash"] == h` (`cli/forge.py:345-347`, printed as "reviews reset"). `drift` compares `sha(p) != d["hash"]` for every deliverable of an approved phase (`cli/forge.py:221-227`). `gate_problems` requires `qa` and `redteam` at the current hash (`cli/forge.py:498-507`).
- **Recommendation** Derived view, never registered. `REQUIRED` and `PREFIX_PHASE` stay untouched (`cli/forge.py:10-23`), so `cmd_register` keeps refusing the name (`cli/forge.py:325-326`).

### F7 — A stale-tracker refusal interacts with the attempt ledger

- **Ref** `cli/forge.py:1409-1431`, `cli/forge.py:1449-1467`, `cli/forge.py:1601-1624`
- **Status** inferred
- **What** `record_attempt` fingerprints the command's whole output and declares `STUCK` after five identical failures; once `gate:check:build` is stuck, `main()` exits 3 before the command body runs. A refusal that embeds a timestamp produces a different fingerprint each time and never trips the limit; one that does not trip it can freeze the gate the tracker was meant to serve.
- **Evidence** `fp = sha256(text.strip()[:2000])` then `e["count"] >= LOOP_LIMIT` (`cli/forge.py:1457-1463`); `op_key` returns `None` for any command it does not name (`cli/forge.py:1431`), so unintended commands are uncounted.
- **Recommendation** The refusal text is fixed (no `now()`), the remedy is one deterministic command, and `op_key` returns `None` for `progress` exactly as it does for `client report`. Cost of the timestamp: a stale tracker can never trip the loop guard. Cost of an entry in `op_key`: a stale document consumes the budget of a functional operation.

### F8 — The CLI cannot write project-language prose, and `client report` already solved that

- **Ref** `skills/forge/SKILL.md:23` (R6), `cli/forge.py:1274-1276`, `cli/forge.py:241`
- **Status** verified
- **What** Deliverables are written in the project language (`lang=` in `forge status`), and the CLI's own strings are English. The one existing owner-facing artifact, the client report, is not written by the CLI: it prints facts and asks the agent to render them in the project language.
- **Evidence** `print(f"- project: {s['project']} | language: {s['lang']} …")` then `"Write the client-facing report in the project language from these facts"` (`cli/forge.py:1274-1276`).
- **Recommendation** Split the file: a generated block with English scaffolding and values quoted verbatim from project-language files (`slices.md` names, plan acceptance lines, journal evidence), plus a preamble outside the markers holding the project-language explanation, written once, containing no fact. The `--check` refuses a preamble that contains a slice id, a status token or a date.

### F9 — A removed slice keeps its row, and the tracker must not count it as pending

- **Ref** `skills/forge-architect/references/slices-format.md:12`, `cli/forge.py:771-774`
- **Status** inferred
- **What** A removed slice keeps its identifier in a `## Removed` section without the leading pipe. `parse_slices` matches `^\|\s*S\d+\s*\|`, so the `Removed` line is invisible to the CLI, while `state.json` may still hold `pending` for it.
- **Evidence** `Identifiers S<n> are never reused. A removed slice keeps its row in a section ## Removed below the table, without the table pipe at the start of the line.`
- **Recommendation** Render from `parse_slices` only (the live rows). Never iterate `s["slices"]` for display: a key absent from the table is a removed or renamed slice, and printing it as "not started" is a false statement to the owner.

### F10 — v2 tried a file and measured the exact failure this design must avoid

- **Ref** v2 `skills/forge/SKILL.md:82-86`, v2 `scripts/state.js:1465-1471` and `1488-1523`, v2 `scripts/state.js:1202-1234`, v2 `references/state-schema.md:13-29`; v2 `templates/memory/SESSION_LOG.md:86-97`
- **Status** verified
- **What** v2 replaced a session-journal reading with one command, `state.js start`, and stated why: a file is rebuilt from conversation memory and then lies without a signal. The measured consequence is written in the skill: 14 slices approved with no test at all, and a tracker that was wrong silently. The same command carried the guard that makes the claim checkable: `sliceReality()` refuses a `done` status with zero test cases, and prints `suspect` entries. Separately, v2 accepted mirrors as a pattern only with one writer and a sync check that exits 1 and offers `--fix` (`state-schema.md:22-29`).
- **Evidence** `Pourquoi une commande et pas un fichier … le suivi qui disait faux sans aucun signal` (v2 `SKILL.md:84`); `sliceReality`: `suspect: /^(approved|done|validated|implemented)$/.test(entry.status) && testCount === 0` (v2 `state.js:1233`); `L'Étape 0 est la seule commande que tout le monde lance, donc c'est le seul endroit où l'information est rendue impossible à manquer` (v2 `state.js:1468-1471`).
- **Recommendation** Take the command, not the prose file: the tracker is generated, never authored, and its `--check` is the v2 `sync` in miniature. Take `sliceReality` too: a slice marked `done` whose plan has zero `TC-` lines is a `suspect` row the tracker prints as a contradiction, not as a completion. `SESSION_LOG.md` and `DECISIONS.md` are not a precedent for this file: they are append-only narratives with no derivable content (`SESSION_LOG.md:99-161`, `DECISIONS.md:18-24`), and copying them into a progress view would be the second home `forge-memory/SKILL.md:17` forbids.

## Recommended design

### Placement and ownership

| Decision | Choice | Why |
|---|---|---|
| Path | `.forge/progress.md` | Everything the CLI governs lives under `.forge/`; `cmd_register` refuses a deliverable outside it (`cli/forge.py:330`), and a root file belongs to no check at all |
| Registration | none | F6: a hash-registered file cannot be regenerated |
| Owner of every fact inside | `state.json` (status), `slices.md` (rows), `plans/index.md` (order, release), `plans/<Sxx>.md` (tasks, acceptance, test cases), `journal.md` (evidence), `validation-report.md` (validation) | I3, `forge-memory/SKILL.md:17` |
| Owner of the file | the CLI, alone | `AGENTS.md` I3: a file a human edits becomes a fourth source that contradicts the CLI |
| Localised prose | the preamble outside the markers, written once at the plans gate | F8 |
| Audience | the non-technical owner, plus the agent as a one-screen answer to "where are we" | replaces nothing: `NOW.md` stays the agent's position (`write_now`, `cli/forge.py:552-559`) |

### Generation and staleness

| Trigger | Call site | Note |
|---|---|---|
| `forge gate approve` for `plans` | after `save` + `journal` in `cmd_gate` (`cli/forge.py:545-547`) | first generation; before this, `forge progress` refuses |
| `forge slice start` | end of `cmd_slice` (`cli/forge.py:875-877`) | after `write_now`, not inside `save` |
| `forge slice done` | end of `cmd_slice` (`cli/forge.py:883-885`) | **after** `journal()`: `save` precedes `journal` on line 884, so rendering inside `save()` would emit `done` with no evidence and never correct it |
| `forge register plan:<Sxx>` / `plans-index` | end of `cmd_register` (`cli/forge.py:348-350`) | a plan fix during build changes task counts |
| `forge phase reopen` | end of `cmd_reopen` (`cli/forge.py:902-906`) | renders the pre-build form |
| `forge progress` | new subcommand | explicit regeneration, same renderer |
| `forge status` | read-only | prints `STALE: .forge/progress.md …; run forge progress` next to the existing `DRIFT:` loop (`cli/forge.py:238-239`); it does not write, because `status` is R1 and must stay a read (`skills/forge/SKILL.md:18`) |

A dedicated subcommand is worth its cost: `--check` needs a caller that is not a state change, and the owner needs a way to refresh the file after pulling someone else's branch. No `--json` variant: a second serialisation is a second contract.

Hand edit, detection and refusal:

1. The renderer is a pure function of files on disk, with no `now()` in it. Any edit inside the markers breaks byte equality.
2. `forge progress --check` renders to memory and compares bytes. Different: `PROGRESS STALE: <first differing line>. Run forge progress.`, exit 1. That is the refusal.
3. `forge progress` overwrites the block and leaves the preamble. It never merges.
4. `forge gate check` for `build` and `validation` adds that same line to its problem list, so the document is current at the two moments it is handed over. Cost: `gate:check:build` can reach `STUCK` after five identical refusals (F7); accepted, because the remedy is one deterministic command and `record_attempt` clears the counter on the success that follows.
5. No refusal at `slice start` or `slice done`. Blocking implementation on a view inverts the priorities and reproduces `docs/archive/LOOPS.md:9` (a gate waiting on an act nothing asks for).

### Content contract

Four questions, four sections, every cell from a named source.

| Section | Answers | Cell | Source | Fallback when the source is missing |
|---|---|---|---|---|
| 1. Plan and order | Q1 | `#`, slice, module, release, served IDs | `plans/index.md` order and release, `parse_slices` for the rest | release empty → `unassigned`; a check line names the fix |
| 2. Status now | Q2, Q4 | `done`/`in progress`/`not started`, current position, next command | `s["slices"]`, `next_action(s, r)` | none; `next_action` always returns a string (`cli/forge.py:252-294`) |
| 3. Checkable results | Q3 | evidence `command : result`, date, task ticks, test-case count, acceptance lines with their ID | journal `slice_done` (repr-decoded), `^- \[[ x]\] T\d+` and `^- TC-<sid>-\d+` (`cli/forge.py:825`, `832`), plan `## Acceptance` | no evidence → `— no evidence recorded`; no ID on an acceptance line → `—`, listed as a defect |
| 4. Releases | Q1, Q3 | per release: slices, how many built, how many validated | section 1 plus `validation-report.md` | validation absent → `built, not validated` |

Rules that keep it honest:

- **No invented number.** No percentage, no estimate, no date of completion. Forge holds none of those.
- **Acceptance is quoted, never summarised.** The words come from the plan, in the project language; the row adds only the test-case id that verifies the same PRD id (`plan-template.md:13-14` ties each criterion to an ID; `TC-… | verifies B1` names the same ID).
- **Tasks are shown as `n/m`, not listed.** The task text and its files belong to the plan; `n/m` is the one thing the plan cannot state about itself.
- **A contradiction is printed, not hidden.** `done` with no evidence line, or a plan with zero `TC-` lines, renders as a `⚠` row and a line under the table, copying v2 `sliceReality` (v2 `state.js:1233`).
- **`built` and `validated` never share a word.** F5.
- **The preamble holds no fact.** Enforced by `--check`.

### Rendered example

Skeleton, with the markers the generator owns:

```
<!-- forge:progress v1 start -->
# Progress: <project>

generated by `forge progress` from .forge/state.json, .forge/slices.md,
.forge/plans/index.md, .forge/plans/, .forge/memory/journal.md and
.forge/validation-report.md. Everything between the two markers is rewritten;
do not edit it.

## 1. Plan and order {#plan-and-order}
| # | Slice | Module | Release | Serves | Status |
|---|---|---|---|---|---|
| <n> | <Sxx> <name> | <module> | <release> | <B,E,V,L ids> | <status> |

## 2. Status now {#status-now}
- built: <n> of <m> | in progress: <n> | not started: <n>
- position: <Sxx>, task <n> of <m>
- next: `<next_action>`
- waiting on you: <n> open point(s), <n> overdue

## 3. Checkable results {#checkable-results}
### <Sxx> <name> — <status>
- evidence: `<command> : <result>` (<date>)
- tasks: <n>/<m> | test cases: <n>
- acceptance, from [the plan](plans/<Sxx>.md):
  - <criterion> — verifies <ID> — checked by <TC-id>
⚠ <contradiction, one line each>

## 4. Releases {#releases}
| Release | Slices | Built | Validated |
|---|---|---|---|
| <MVP / R1 / R2> | <Sxx,…> | <n>/<m> | <n>/<m> or — |
<!-- forge:progress v1 end -->
```

Fully rendered for four slices across two releases, S01 and S02 finished, S03 half-built:

```markdown
<!-- forge:progress v1 start -->
# Progress: GestionLocative

generated by `forge progress` from .forge/state.json, .forge/slices.md,
.forge/plans/index.md, .forge/plans/, .forge/memory/journal.md and
.forge/validation-report.md. Everything between the two markers is rewritten;
do not edit it.

## 1. Plan and order {#plan-and-order}
| # | Slice | Module | Release | Serves | Status |
|---|---|---|---|---|---|
| 1 | S01 App shell and layouts | foundation | MVP | C1 | done |
| 2 | S02 Card payment | billing | MVP | B1,B2,E1,V1 | done |
| 3 | S03 Refund request | billing | R1 | B2,E2 | in progress |
| 4 | S04 Receipts | billing | R1 | B3 | not started |

## 2. Status now {#status-now}
- built: 2 of 4 | in progress: 1 | not started: 1
- position: S03, task 3 of 7
- next: `forge slice done S03 --evidence "<command> : <result>"`
- waiting on you: 0 open point(s), 0 overdue

## 3. Checkable results {#checkable-results}
### S01 App shell and layouts — done
- evidence: `flutter test test/shell_test.dart : 12 passed` (2026-10-22)
- tasks: 6/6 | test cases: 3
- acceptance, from [the plan](plans/S01.md):
  - The shell renders at 320 px without horizontal scroll — verifies C1 — checked by TC-S01-2
  - Every layout region named in `layouts.md` has an element — verifies C1 — checked by TC-S01-3

### S02 Card payment — done
- evidence: `flutter test test/pay_test.dart : 9 passed` (2026-10-24)
- tasks: 8/8 | test cases: 5
- acceptance, from [the plan](plans/S02.md):
  - A card payment reaches the provider and returns a paid order — verifies B1 — checked by TC-S02-1
  - A refund requested within 14 days is accepted, day 15 refused — verifies B2 — checked by TC-S02-2
  - A declined card shows the reason and keeps the basket — verifies E1 — checked by TC-S02-4

### S03 Refund request — in progress
- evidence: — no evidence recorded (a slice is only checked when it is done)
- tasks: 3/7 | test cases: 4
- acceptance, from [the plan](plans/S03.md):
  - A refund over 50 EUR needs an owner approval — verifies B2 — checked by TC-S03-1
  - A refund on a settled payment creates a credit note — verifies E2 — checked by TC-S03-3

### S04 Receipts — not started
- tasks: 0/5 | test cases: 3

## 4. Releases {#releases}
| Release | Slices | Built | Validated |
|---|---|---|---|
| MVP | S01, S02 | 2/2 | — not validated (validation phase not started) |
| R1 | S03, S04 | 0/2 | — |
<!-- forge:progress v1 end -->

## What this file is, and how to check it

It restates facts that already exist in `.forge/`, in the order you read them. It is
regenerated by `forge progress`; a hand edit is reported by `forge status` and refused
by `forge progress --check`. A slice counted as built carries a real command and its
result: run the command yourself to verify it.
```

(The preamble is project-language in a real project; it is English here because this repository's files are English.)

### What the CLI can enforce, and what each option costs

| Option | Cost | Buys | Verdict |
|---|---|---|---|
| Nothing (documentation only) | 0 | — | reject: v2 measured this failure (F10) |
| Byte compare in `progress --check` | ~40 lines, 1 `flow.sh` case | detection when run | keep |
| `forge status` reports it, read-only | 1 loop beside `drift` (`cli/forge.py:238-239`), 1 line | every invocation sees it, because `status` is R1 | keep |
| `gate check` refuses it for `build` and `validation` | 6 lines in `gate_problems`, 1 case, 1 audit row | the document cannot be stale when it is handed over | keep, with F7's caveat |
| A digest in the header | 1 field, 1 explanation, 1 more way to be wrong | nothing that byte equality does not already give | reject |
| Registered deliverable in `REQUIRED` | `HEADINGS` entry, a template, `templates.sh` case, two reviews per regeneration, permanent drift | a reviewed document | reject (F6) |

Definition of done for an implementation, per `AGENTS.md` I4 and I10: `tests/progress.sh` proving (a) the block changes at `slice done`, (b) `--check` exits 1 after a hand edit, (c) `forge progress` refuses before the plans gate, (d) a `done` slice with no `TC-` line renders a contradiction; plus a row in `docs/ESCAPE-HATCH-AUDIT.md` and the suite count in `docs/STATUS.md`. New normative text in `skills/forge-build/SKILL.md` passes `python3 cli/forge.py lint-rules skills agents AGENTS.md` with 0 hits (I5).

## Alternatives considered

| Alternative | Argument for | Why it loses |
|---|---|---|
| Registered deliverable `work-tracker` in `REQUIRED`, two reviews, gated | It would be reviewed and cannot be silently wrong | F6: every regeneration resets the reviews and creates `DRIFT`; the plans gate would need two reviews per slice completion, which is `docs/archive/LOOPS.md:14` rebuilt by design |
| `forge status --verbose` only, no file | One command, no second copy, the v2 answer (F10) | The owner does not run commands, and `status` is the agent's position, not the plans; the four questions need plan content that `status` does not read |
| Static file written once at the plans gate, then hand-maintained | Zero code | It becomes the fourth source of truth that I3 forbids, and v2 measured the result: "the tracking said false with no signal" (v2 `SKILL.md:84`) |
| Tracker generated only at client touchpoints | Fits the existing liaison flow (`skills/forge/SKILL.md:43`) | It would answer "where are we" five times in a project, and never during build, which is the only phase where the question changes daily |
| Reuse `.forge/memory/NOW.md` as the tracker | It already holds position and next action (`cli/forge.py:555-559`) | 6 lines, overwritten at every checkpoint, agent-oriented, no slice table; widening it makes the agent's position document answer to a second reader |

## Rejected candidates

| Candidate | Why not |
|---|---|
| Percentage complete | Nothing in the state weighs slices; the number would be invented |
| Dates, durations, Gantt | The only dates Forge holds are client deadlines (`forge client ask --by`) and journal timestamps |
| A row per task for all slices | Up to 15 × N rows duplicating the plans; the plan is one click away and owns the text |
| Lines of code, files touched, commits | Forge measures none of these; `write_now --files` is agent-declared and unverified |
| Per-slice review verdicts | Reviews attach to deliverables, not slices; a plan's verdict is about the plan, not the build |
| A JSON twin (`progress --json`) | A second serialisation to keep in step; `state.json` is already the machine form |
| Writing it from `save()` | `save` is called before `journal` on `slice done` (`cli/forge.py:884`), so the render would show `done` without evidence |
| Putting the release column in `slices.md` | `parse_slices` drops the fifth cell (column probe above); it would be dead data until the parser, the format doc and the tests all move |
| A "Removed" row listed as not started | `slices-format.md:12` keeps removed ids in a section the parser ignores; printing them is a false statement (F9) |

## Open questions

1. **Task-level detail: needed or noise?** If the owner reads only slice rows, F2 loses its urgency and the tracker drops `n/m`. Owner's answer changes whether F2 ships first.
2. **What to call `done` before validation.** "Built" is honest and unfamiliar. The alternative, "done, not yet verified", is longer but removes the ambiguity F5 describes.
3. **Should client points appear?** They are facts in `state.client` and overdue points matter to the owner, but they are also the client-report's subject (`cli/forge.py:1287-1294`). Two places saying "1 point overdue" is a second home unless the tracker derives it from the same fields and never stores it.
4. **Is a stale tracker allowed to block the build gate?** Recommended yes. The cost is a `STUCK` path on `gate:check:build` (F7); the alternative is a document that can be stale at the exact moment it is the deliverable.
5. **Does the reopen trap need fixing first?** `cmd_reopen` leaves `s["slices"]` untouched (`cli/forge.py:896-901`). The pre-build form hides the slice table, which masks the stale values rather than fixing them; clearing them in `cmd_reopen` needs its own decision and test.
6. **Where does the preamble's one-time text come from?** Written by the agent at the plans gate in the project language, or copied by the installer from a per-language template. Unverified which the maintainer prefers; both keep facts out of the preamble.
