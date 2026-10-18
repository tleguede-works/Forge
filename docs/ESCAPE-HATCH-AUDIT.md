# Escape-hatch audit

Method: read every normative file (`skills/*/SKILL.md`, `agents/*.md`, CLI) as an agent that wants to finish faster, list each shortcut, then decide: closed by the CLI, or left to judgement and named as such. Every closed item has a test in `tests/`.

## Closed by the CLI

| # | Shortcut | Closed by | Test |
|---|---|---|---|
| 1 | Edit `state.json` by hand | Sealed state; every command refuses a mismatch | adversarial 1 |
| 2 | Edit an approved deliverable silently | `DRIFT` report, next phase refused until reopen | adversarial 8 |
| 3 | Reopen without saying why | `phase reopen` needs a reason, resets downstream reviews, logs a decision | adversarial 9 |
| 4 | Start a later phase / register a later deliverable | Phase order and phase check | e2e, adversarial 5 |
| 5 | One reviewer instead of two | Gate needs `qa` and `redteam` on the current hash | adversarial 3 |
| 6 | Review of an older version | Review bound to the file hash | adversarial 7 |
| 7 | Review report written anywhere, or edited after it was recorded | Report path fixed to `.forge/reviews/<name>.<agent>.json`; its hash is recorded and re-checked by the gate | adversarial 11, 12 |
| 8 | Dismiss a blocking finding with a throwaway reason | Reason must be a decision ID that exists in `decisions.md` | adversarial 13 |
| 9 | Switch to client mode to get `auto` approvals | `forge mode` needs the user's words as evidence; journaled; `auto` refused in touchpoint phases | adversarial 11, e2e |
| 10 | `slice done` with a claim and no result | Evidence must read `<command> : <result>` | flow |
| 11 | Placeholders in a deliverable | Registration refuses `TODO`, `TBD`, `{{TOKEN}}` | adversarial 10 |
| 12 | Edit the installed kit (CLI, skills) to relax a rule | `kit.sha256` manifest; `status` warns, `gate approve` refuses | install |
| 13 | A requirement served by no slice, a slice serving a withdrawn requirement | `check coverage` in the architecture gate | flow |
| 14 | A layout region with no implementation task | `design check --plans` in the plans gate | design |
| 15 | Two screens in one file, action ranked above its context | `design check` in the design gate | design |
| 16 | A rule set with vague wording, hedges, no command-backed gates, over budget | `forge rules audit` | rules |

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
