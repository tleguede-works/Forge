# Migrating from Forge v2

## What changed

| Area | v2 | v3 |
|---|---|---|
| Entry file | one `SKILL.md` of 1289 lines | `forge` router plus seven phase skills, each under 500 lines |
| State changes | nine JavaScript scripts with different syntaxes | one Python CLI, `forge` |
| State file | front matter mirror and long schema | one `status` field per item, sealed |
| Phases | benchmark in phase 1 step 1.5 and again in phase 3.1 under one file name | landscape research first (phase 1), PRD second, roadmap third; visual references live in design |
| Fast Track | automated phases 4 and 5, an exception to the gates | removed; client mode reduces questions and keeps every gate |
| Agents | 11, with QA and Red Team wired in only through Fast Track | 8; QA and Red Team are required by the CLI for every deliverable |
| Review | prose instruction | hash-bound JSON reports, gate refuses without two current reviews |
| Memory | context, session log, decisions, lessons plus findings in state | `NOW.md`, journal, decisions, lessons; hooks for compaction |
| Compliance | not covered | phase `compliance` before the PRD, with a sourced register and rechecks |
| Client touchpoints | contract and acceptance | bootstrap, compliance, prd, roadmap, design, validation, each with a liaison review |
| Rules generator | Project Rules Architect, called from the main skill, Node audit | `forge-rules`, its own `rules` phase between architecture and plans, `forge rules audit` in Python run by the gate |

## Moving an existing v2 project

There is no automatic migration, on purpose: a v2 state file carries approvals that v3 would otherwise have to trust.

1. Install v3 and run `forge init --name <name> --lang <code>` in the project.
2. Start each phase in order with `forge phase start <phase>`.
3. Copy each existing deliverable into `.forge/` under the v3 name, adapt the formats the CLI parses (`screen-map.md`, `layouts.md`, `slices.md`, plan files), and register it.
4. Run the two reviews and the gate for each phase. A v2 approval is not carried over.
5. Keep the v2 folder until the v3 gates pass, then archive it.

## Removing v2

Delete the globally installed v2 skill folder and its agents before installing v3, so two `forge` skills never load together.
