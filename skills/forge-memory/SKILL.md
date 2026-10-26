---
name: forge-memory
description: Project memory for long agent sessions that survive context compaction. Use at session start, after any context summary, before commits, when a decision is made or rejected, when the same mistake happens twice, and whenever a .forge/memory folder exists or an AGENTS.md lacks a forge memory section.
---

# Forge Memory

Memory lives in `.forge/memory/`. Three layers, each with one writer command.

| Layer | File | Content | Written by |
|---|---|---|---|
| Present | `NOW.md` | Current task, next exact action, files touched, blockers. At most 30 lines. Overwritten each time | `forge memory checkpoint` |
| Past | `journal.md` | One line per event. Append-only | CLI commands, `forge memory log` |
| Past | `lessons.md` | Mistakes and workarounds, one entry each | `forge memory learn` |
| Durable | `decisions.md` | Decisions and rejected options, with the reason | `forge memory decide` |

One fact has one home. Position in the project is `state.json` plus `NOW.md`. Why something was decided is `decisions.md`. What went wrong is `lessons.md`. Never copy a fact into a second file.

## Startup procedure

Run at the start of every session and after every context compaction:

1. Find the agent file: `AGENTS.md` at the project root (Claude Code also reads `CLAUDE.md`).
2. Check that it contains the `forge:start` block. If it is missing or outdated, run `forge init` for a new project or restore the block from the installed template, then tell the user.
3. Run `forge memory resume` and read the whole output before any other action.
4. Check that hooks are installed (`forge hooks status`). If they are missing, tell the user that memory runs in degraded mode and keep every conditional trigger below.

## Triggers

Mechanical triggers are fired by hooks. Conditional triggers are fired by you when you recognize the condition.

| # | Trigger | Kind | Action |
|---|---|---|---|
| 1 | Session start | hook | `forge memory resume` |
| 2 | Before context compaction | hook | `forge memory checkpoint` with the real task and next action |
| 3 | After context compaction | hook | `forge memory resume` |
| 4 | Every 10 file edits | hook | `forge memory checkpoint` |
| 5 | Phase start, phase approval | CLI | automatic checkpoint |
| 6 | Before a commit | conditional | `forge memory checkpoint` |
| 7 | Before and after launching a subagent | conditional | `forge memory log` with the delegation and the result |
| 8 | A decision is taken or an option is rejected | conditional | `forge memory decide` with the reason |
| 9 | The same mistake happens twice, or you find a workaround | conditional | `forge memory learn` |
| 10 | The user corrects you or states a lasting instruction | conditional | `forge memory log`, plus `learn` if it lasts |
| 11 | A gate fails | CLI | automatic `gate_blocked` journal entry; a review refusal is counted by `forge attempts` |
| 12 | Session end | hook, best effort | `forge memory checkpoint`; never the only safety net |

When a trigger fires, write immediately. Do not postpone to a later trigger.

## Quality of a checkpoint

- `--task` names the exact thing in progress, not the phase.
- `--next` is one action that a reader with no context can run.
- Rejected options go to `decisions.md`, because a rejected option is the first thing lost in compaction.
