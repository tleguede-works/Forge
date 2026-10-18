# Forge Rules: analysis of Project Rules Architect and what changed

## Weaknesses found in Project Rules Architect

| # | Weakness | Evidence | Fix in forge-rules |
|---|---|---|---|
| 1 | Oversized entry file | SKILL.md had 721 lines, above the 500-line guideline | SKILL.md is under 100 lines; principles and workflow moved to `references/` |
| 2 | Audit needs Node | `rules-selftest.js` (814 lines) and `selftest.js` | Ported to `forge rules audit` (Python, one CLI); mutation tests in `tests/rules.sh` |
| 3 | The budget check never fails on the total | `checkBudget` returns `ok` from the per-file ceiling only, while principle 6b says the total is the hard limit on a target without scoping | `--budget` total is enforced and fails the check |
| 4 | Gate check is keyword presence | `checkGates` passes when the word "test" appears anywhere and one `exit 0` appears anywhere | Each gate must appear on a line with a command in backticks; a pass condition must exist |
| 5 | Wiring check covers OpenCode only | `checkWiring` reads `opencode.json` | `--target` selects opencode, claude (CLAUDE.md imports AGENTS.md) or agents |
| 6 | Vague-wording list is short | `VAGUE` misses "should", "try to", "consider", "ideally", "generally" | The list now includes them, in English and French |
| 7 | Coupling check names obsolete tools | `FORGE_INTERNAL` lists `forge-guard`, `state.js` and other v2 scripts | Replaced by the v3 CLI commands and agent names; the forge block in AGENTS.md is exempt |
| 8 | Hidden coupling to the planner | SKILL.md section "Working alongside a planning skill" made it a callee of Forge v2 | Removed; Forge calls `forge-rules` as a normal skill |
| 9 | Memory scaffold lived in two systems | A "context scaffold" mode and four memory templates duplicated `forge-memory` | Scaffold mode and templates removed; templates use neutral names (the decisions log, the session journal, the lessons log) |
| 10 | Provenance loaded by accident | 441-line provenance file sat in `references/` | Moved to `docs/forge-rules/provenance.md`, outside the skill folder |
| 11 | Command in a code span escaped the clarity check | `stripCodeSpans` ran on every check | The coupling check now inspects code spans; the clarity check still strips them |
| 13 | 120 soft-wording hits in templates and references | should, may, usually, at least and similar | Rewritten; the wording lint now covers `forge-rules/references/`; banned words are listed once in `references/banned-wording.md` |
| 12 | Sentence-level escape hatch | "If the user says just generate something reasonable, don't force the interview" | Kept only for the interview; F1 to F10 apply in full |

## Known limits of the audit

- Thresholds, cross-references and contamination are pattern matches in English and French. A rule set in another language passes them silently; the tool prints the language limit in the audit checklist.
- The judgement half of the audit (content preservation, contradiction with code, provenance) stays manual and is reported as such.
- Templates still contain a conditional on where learnings live (`entry-file.md`). It needs a manual rewrite to point at the lessons log; pending.
