---
name: forge
description: Drives a software product from raw idea to a code-ready plan through gated phases (landscape research, PRD, roadmap, design, architecture, plans, build, validation). Use for any new project, for "continue the project", "where are we", "next phase", or any request that touches the .forge folder. Always load this skill first when a .forge folder exists.
---

# Forge

Forge turns an idea into a verified, implementable plan. It works in ordered phases. The `forge` CLI enforces the order and the gates. This file tells you what to do; the CLI tells you whether it is allowed.

## Locating the CLI

The CLI is `forge` on the PATH after installation. If the command is missing, stop and tell the user to run the installer. Do not recreate it.

## Golden rules

Each rule has an ID. Cite the ID when you refuse or stop.

- **R1 Status first.** On every invocation, run `forge status` and act on its `next:` line. Never rely on conversation memory for the project position.
- **R2 CLI only.** Change state with the `forge` CLI only. Never edit `.forge/state.json`, `.forge/memory/journal.md` or review hashes by hand.
- **R3 Phase order.** Phases run in this order: bootstrap, landscape, prd, roadmap, design, architecture, rules, plans, build, validation. The CLI refuses to start a phase before the previous one is approved, and refuses to register a deliverable outside its phase.
- **R4 Two reviewers per deliverable.** Every deliverable is reviewed by the `forge-qa` agent (finds what is missing) and by the `forge-redteam` agent (finds contradictions and problems), each in its own context, never by the agent that wrote it. `forge gate` refuses a deliverable without both reviews on its current version.
- **R5 No self-approval.** A phase is approved only with `forge gate approve --evidence "<the user's own words>"`. In client mode, phases outside the touchpoint list use `--evidence auto`. You never invent evidence.
- **R6 Language.** Write every deliverable in the project language shown by `forge status` (`lang=`). Repository files and CLI output stay in English.
- **R7 Memory.** Follow the `forge-memory` skill: resume at session start, checkpoint at every trigger it lists.
- **R8 No subagent, no review.** If your tool cannot launch a separate agent for review, stop the phase and tell the user. Reviewing your own work does not count.
- **R9 Stop, do not work around.** If a rule cannot be satisfied, stop and report which rule (by ID) blocks you and what you need. A workaround is a violation.
- **R10 No premature work.** Do not draft the deliverable of a later phase before the current phase is approved.

## Modes

Read the mode in `forge status`.

| Mode | Questions to the user | Gates |
|---|---|---|
| `interactive` | Ask at each decision point and show progress after each deliverable | All gates apply |
| `client` | Treat the user as a client with no development knowledge. Speak in business terms. Ask only at the touchpoints: bootstrap (contract), prd, design, validation. Batch questions. Send a progress report at each phase end | All gates apply, identical |

In client mode, record every question that needs the client with `forge client ask --what ... --price ... --by YYYY-MM-DD --if-no-answer ...` (all four are required). Run `forge client sweep` at each progress report: overdue points take their stated default and you report them.

Switch with `forge mode interactive|client --evidence "<the user's words>"`. Only the user changes the mode; you never switch it to gain `auto` approvals.

**Touchpoint procedure (client mode, phases bootstrap, prd, design, validation).** Write a plain-language summary at `.forge/client/<phase>-summary.md`. Run the `forge-client-liaison` agent on it; it writes `.forge/reviews/<phase>.client.json` with its questions. Fix the summary, add a `resolution` to every question, then run `forge client review --phase <phase> --document .forge/client/<phase>-summary.md --report .forge/reviews/<phase>.client.json`. `forge gate approve` refuses without it, or when the summary changed after the review.

At each phase end in client mode, run `forge client report`, write the client-facing report in the project language from its facts, and run the `forge-client-liaison` agent on it. Mode changes how you talk, never which checks run.

## Phase procedure

For the current phase:

1. Run `forge status`. Read the `next:` line.
2. Load the phase skill: bootstrap uses `forge-bootstrap`; landscape, prd and roadmap use `forge-discover`; design uses `forge-design`; architecture uses `forge-architect`; rules uses `forge-rules`; plans uses `forge-plan`; build and validation use `forge-build`. If that skill is not installed, stop (R9).
3. Produce the deliverables in `.forge/`, then `forge register <name> <path>`.
4. Launch the `forge-qa` and `forge-redteam` agents on each deliverable. Each writes a JSON report; record it with `forge review <name> --agent qa|redteam --report <file>`.
5. Fix every blocking finding, re-register, and re-run both reviews. A changed file resets its reviews.
6. Run `forge gate check`. When it passes, ask the user for approval (client mode: only at touchpoints), then `forge gate approve --evidence "..."`.
7. Run `forge memory checkpoint`.

## Reports

A review report is a JSON file that the reviewing agent writes at `.forge/reviews/<name>.<agent>.json` (the `:` in `screen:<id>` becomes `_`). The CLI accepts that path only, and a gate fails if the report changes after it was recorded. The file shape is: `{"findings":[{"id","severity","status","evidence","reason?"}]}`. Severity is `critical`, `major` or `minor`. Status is `open`, `resolved` or `dismissed`. A dismissed finding carries a `reason` that is the ID of a decision recorded first with `forge memory decide` (for example `D-003`). The CLI refuses any other reason.
