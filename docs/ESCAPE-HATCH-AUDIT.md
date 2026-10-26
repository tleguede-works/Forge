# Escape-hatch audit

Method: read every normative file (`skills/*/SKILL.md`, `agents/*.md`, CLI) as an agent that wants to finish faster, list each shortcut, then decide: closed by the CLI, or left to judgement and named as such. Every closed item has a test in `tests/`.

## Closed by the CLI

| # | Shortcut | Closed by | Test |
|---|---|---|---|
| 1 | Edit `state.json` by hand | Sealed state; every command refuses a mismatch | adversarial 1 |
| 2 | Edit an approved deliverable silently | `DRIFT` report, next phase refused until reopen | adversarial 8 |
| 3 | Reopen without saying why | `phase reopen` needs a reason and resets the whole subtree (later phases, their reviews, the compliance rechecks, the client reviews, the build slices, the loop counters) | adversarial 9, validation |
| 4 | Start a later phase / register a later deliverable | Phase order and phase check | e2e, adversarial 5 |
| 5 | One reviewer instead of two | Gate needs `qa` and `redteam` on the current hash | adversarial 3 |
| 6 | Review of an older version | Review bound to the file hash | adversarial 7 |
| 7 | Review report written anywhere, or edited after it was recorded | Report path fixed to `.forge/reviews/<name>.<agent>.json`; its hash is recorded and re-checked by the gate | adversarial 11, 12 |
| 8 | Dismiss a blocking finding with a throwaway reason | Reason must be a decision ID that exists in `decisions.md` | adversarial 13 |
| 9 | Switch to client mode to get `auto` approvals | `forge mode` needs the user's words as evidence; journaled; `auto` refused in touchpoint phases | adversarial 11, e2e |
| 10 | `slice done` with a claim and no result | Evidence must read `<command> : <result>`; the command names a test file that exists or a known runner, and the result states a count or a verdict | flow, validation |
| 11 | Placeholders in a deliverable | Registration refuses `TODO`, `TBD`, `{{TOKEN}}`, `<fill>` and every template token (`<rule>`, `<Sxx>`, `<product name>`) while sparing real HTML tags | adversarial 10, validation |
| 12 | Edit the installed kit (CLI, skills) to relax a rule | `kit.sha256` manifest; `status` warns, `gate approve` refuses | install |
| 13 | A requirement served by no slice, a slice serving a withdrawn requirement | `check coverage` in the architecture gate | flow |
| 14 | A layout region with no implementation task | `design check --plans` in the plans gate | design |
| 15 | Two screens in one file, action ranked above its context | `design check` in the design gate | design |
| 16 | A rule set with vague wording, hedges, no command-backed gates, over budget | `forge rules audit` | rules |
| 17 | One `x` under each heading | Every section of a deliverable holds at least 8 characters of text once its markup and tables are stripped | validation |
| 18 | A table-based deliverable with no row | `slices`, `screen-map` and `plans-index` need a data row with the full column count; `layouts` needs a `LAY-` section and a `region:` line | templates, register |
| 19 | A validation report that only exists | The gate compares the report with the `TC-` cases of the plans and the test plan, refuses a missing or invented case, a row with no evidence, a command that is not a test command, a verdict outside pass/fail/blocked, a slice it never mentions and an applicable obligation with no result | validation |
| 20 | A one-word requirement with a source | The requirement is measured after its source clause is removed: `- B1 x (source: user-stated)` is refused | validation |
| 21 | Ticking a plan task and calling it drift-free *or* done | The plan hash ignores task checkboxes, so a tick is progress and not a content change; the build gate still reads `state.json`, never the ticks | validation |
| 22 | A low-contrast text colour, or a stated ratio the values do not produce | `design check` computes the WCAG ratio from the two hex values and refuses text under 4.5:1 (3:1 when the row says large) | design |
| 23 | A hand-edited progress tracker | `forge progress --check` compares the file with the text regenerated from the state; the build and validation gates regenerate it rather than trust it | progress |

## Left to judgement (named, not hidden)

| # | Shortcut | Why the CLI cannot close it | Mitigation |
|---|---|---|---|
| J1 | The orchestrator writes the review report itself instead of a separate agent | The CLI cannot see who wrote a file | R8 in the `forge` skill; the user can read `.forge/reviews/` and the journal |
| J2 | Invented approval words in `--evidence` | The CLI cannot hear the user | Evidence is journaled verbatim; the user can audit `journal.md` |
| J3 | Skipping a conditional memory trigger (triggers 6 to 10) | No tool event marks them | Mechanical triggers 1 to 5 and 12 cover the loss of position; `NOW.md` is rewritten at every phase and slice change |
| J4 | Quality of a hierarchy ranking beyond H1 and H2 | Needs design judgement | Review checklist for `forge-qa` and `forge-redteam` |
| J5 | Deleting `.forge/` entirely | Nothing remains to check | Keep `.forge/` under version control |
| J6 | Running the CLI from a modified source checkout | The manifest exists only for the installed kit | Install with the installer for real projects |
| J7 | The seal is not a signature | The CLI source is readable | It stops careless edits, not a forger |

## Wording findings fixed in this pass

- "after the user agrees" (forge-build B2) had no client-mode path: now `forge client ask --kind deviation`.
- "Dismissed" findings had an unchecked `reason`: now tied to a decision entry.
- The `forge` skill told agents to pass `--report <file>` with no location: now fixed by contract.
