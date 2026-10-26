---
name: forge
description: Drives a software product from raw idea to a code-ready plan through gated phases (bootstrap, landscape, compliance, PRD, roadmap, design, architecture, rules, plans, build, validation). Use for any new project, for "continue the project", "where are we", "next phase", or any request that touches the .forge folder. Always load this skill first when a .forge folder exists.
---

# Forge

Forge turns an idea into a verified, implementable plan. It works in ordered phases. The `forge` CLI enforces the order and the gates. This file tells you what to do; the CLI tells you whether it is allowed.

## Locating the CLI

The CLI is `forge` on the PATH after a global installation. A project installation ships `.forge/bin/forge`, and the Forge block of `AGENTS.md` names it. If neither command exists, stop and tell the user to run the installer. Do not recreate it.

## Golden rules

Each rule has an ID. Cite the ID when you refuse or stop.

- **R1 Status first.** On every invocation, run `forge status` and act on its `next:` line. Never rely on conversation memory for the project position.
- **R2 CLI only.** Change state with the `forge` CLI only. Never edit `.forge/state.json`, `.forge/memory/journal.md` or review hashes by hand.
- **R3 Phase order.** Phases run in this order: bootstrap, landscape, compliance, prd, roadmap, design, architecture, rules, plans, build, validation. The CLI refuses to start a phase before the previous one is approved, and refuses to register a deliverable outside its phase.
- **R4 Two reviewers per deliverable.** Every deliverable is reviewed by the `forge-qa` agent (finds what is missing) and by the `forge-redteam` agent (finds contradictions and problems), each in its own context, never by the agent that wrote it. `forge gate` refuses a deliverable without both reviews on its current version.
- **R5 No self-approval.** A phase is approved only with `forge gate approve --evidence "<the user's own words>"`. In client mode, phases outside the touchpoint list use `--evidence auto`. You never invent evidence.
- **R6 Language.** Write every deliverable in the project language shown by `forge status` (`lang=`). Repository files and CLI output stay in English. In a project whose language is not English, translate each heading and keep its anchor, for example `## 3. Règles métier {#business-rules}`: `forge template <name>` prints the anchors, and the CLI matches sections by anchor.
- **R7 Memory.** Follow the `forge-memory` skill: resume at session start, checkpoint at every trigger it lists.
- **R8 No subagent, no review.** If your tool cannot launch a separate agent for review, stop the phase and tell the user. Reviewing your own work does not count.
- **R9 Stop, do not work around.** If a rule cannot be satisfied, stop and report which rule (by ID) blocks you and what you need. A workaround is a violation.
- **R10 No premature work.** Do not draft the deliverable of a later phase before the current phase is approved.
- **R11 Loop guard.** Never repeat an operation that just failed without changing something first. After the second identical failure, stop and diagnose. The CLI stops an operation after five identical failures (`STUCK`) and after three review rounds that end with blocking findings (`ESCALATE`): run `forge attempts`, write the likely cause, then `forge unstick <key> --analysis "..." (--new-approach "..." | --user-answer "...")`. A second stop on the same operation needs the user's answer. A refusal that starts with `NEEDS-USER` means ask the user now, in one message: do not retry it and do not delegate it. When information is missing, search `.forge/` and the repository once; if it is not there, ask the user instead of searching or delegating again. Launch a reviewer once per `forge review begin`.

## Modes

Read the mode in `forge status`.

| Mode | Questions to the user | Gates |
|---|---|---|
| `interactive` | Ask at each decision point and show progress after each deliverable | All gates apply |
| `client` | Treat the user as a client with no development knowledge. Speak in business terms. Ask only at the touchpoints: bootstrap, compliance, prd, roadmap, design, validation. Batch questions. Send a progress report at each phase end | All gates apply, identical |

In client mode, record every question that needs the client with `forge client ask --what ... --price ... --by YYYY-MM-DD --if-no-answer ...` (all four are required). Run `forge client sweep` at each progress report: overdue points take their stated default and you report them.

Switch with `forge mode interactive|client --evidence "<the user's words>"`. Only the user changes the mode; you never switch it to gain `auto` approvals.

**Touchpoint procedure (client mode, phases bootstrap, compliance, prd, roadmap, design, validation).** Write a plain-language summary at `.forge/client/<phase>-summary.md`. Run the `forge-client-liaison` agent on it; it writes `.forge/reviews/<phase>.client.json` with its questions. Fix the summary, add a `resolution` to every question, then run `forge client review --phase <phase> --document .forge/client/<phase>-summary.md --report .forge/reviews/<phase>.client.json`. `forge gate approve` refuses without it, or when the summary changed after the review.

At each phase end in client mode, run `forge client report`, write the client-facing report in the project language from its facts, and run the `forge-client-liaison` agent on it. Mode changes how you talk, never which checks run.

## Phase procedure

For the current phase:

1. Run `forge status`. Read the `next:` line.
2. Load the skill named by the `skill:` line of `forge status`; `producer:` names the agent to delegate the deliverable to. If that skill is not installed, stop (R9). The phase order and the mapping live in the CLI, never in this file.
3. Produce the deliverables in `.forge/`, then `forge register <name> <path>`.
4. For each deliverable and each reviewer, run `forge review begin <name> --agent qa|redteam`, launch that reviewer once (`forge-qa` finds what is missing, `forge-redteam` finds contradictions and problems), then run `forge review record <name> --agent qa|redteam --report .forge/reviews/<name>.<agent>.json`. Never launch a reviewer without a `begin`, and never twice for one `begin`.
5. Sort every blocking finding. `needs: producer`: fix it from the project files. `needs: user`: only the user can settle it, so ask in one batched message. Then `forge register` again (a changed file resets its reviews) and begin the reviews again. A reviewer is never run again on an unchanged version; the CLI refuses it.
6. Run `forge gate check`. When it passes, ask the user for approval (client mode: only at touchpoints), then `forge gate approve --evidence "..."`.
7. Run `forge memory checkpoint`.

## Transitions

| Action | Command | Refused when |
|---|---|---|
| Start the next phase | `forge phase start <phase>` | the previous phase is not approved, or a registered deliverable drifted |
| Approve a phase | `forge gate approve --evidence "<the user's words>"` | the gate check fails, a review is missing, or the evidence is empty |
| Change an approved phase | `forge phase reopen <phase> --reason "<what changed>"` | the phase is not approved, or the reason is shorter than 8 characters |
| Move inside a phase | `forge register <name> <path>` after editing | the phase is not in progress, or the deliverable structure is incomplete |
| Read the position | `forge status` | the state was edited outside the CLI |

A reopen resets every later phase, their reviews, the compliance rechecks, the client reviews and the build slices. Re-run what it reset; never restore a slice to `done` by hand.

## Progress file

`forge progress` writes `.forge/progress.md`, a derived view for a human: phases, slices grouped by release, task counts, evidence, acceptance criteria and test cases. It is never evidence and is never edited by hand. The build and validation gates regenerate it from the state, and `forge progress --check` refuses a hand edit.

## Reports

A review report is a JSON file that the reviewing agent writes at `.forge/reviews/<name>.<agent>.json` (the `:` in `screen:<id>` becomes `_`). The CLI accepts that path only, and a gate fails if the report changes after it was recorded. The file shape is: `{"findings":[{"id","severity","status","evidence","reason?"}]}`. Severity is `critical`, `major` or `minor`. `needs` is `producer` (the default: the author can fix it from the project files) or `user` (the answer exists nowhere in the project and only the user can give it). Status is `open`, `resolved` or `dismissed`. A dismissed finding carries a `reason` that is the ID of a decision recorded first with `forge memory decide` (for example `D-003`). The CLI refuses any other reason.
