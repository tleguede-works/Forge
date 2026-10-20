# Forge

Gated, CLI-enforced workflow that turns an idea into a verified, code-ready plan, then builds it slice by slice. Works with Claude Code and OpenCode.

Status: **v3 rebuild in progress.** See `docs/STATUS.md` for what exists and what is pending, and `docs/IMPROVEMENTS.md` for the improvements under study.

## Install

Forge installs in one of two scopes:

| Scope | Where | Use it when |
|---|---|---|
| **Global** | The kit in `~/.forge`; skills, agents and hooks in the user-level folders of Claude Code (`~/.claude`) and OpenCode (`~/.config/opencode`); the `forge` command on your PATH | You work on your own projects and want Forge everywhere |
| **Local** | The kit in `<project>/.forge/kit`; skills, agents and hooks in the project's `.claude` and `.opencode`; the command is `.forge/bin/forge` | You want the project self-contained, shared with a team through version control, or pinned to one Forge version |

Without `--scope` the installer asks, on the terminal. With no terminal (for example inside a script) it installs globally.

Linux and macOS, from the project root for a local install:

```
curl -fsSL https://raw.githubusercontent.com/tleguede-works/Forge/main/install.sh | sh
curl -fsSL https://raw.githubusercontent.com/tleguede-works/Forge/main/install.sh | sh -s -- --scope local
```

Windows (PowerShell):

```
irm https://raw.githubusercontent.com/tleguede-works/Forge/main/install.ps1 | iex
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/tleguede-works/Forge/main/install.ps1))) --scope local
```

Other options: `--target claude|opencode|both` (default: detected), `--project DIR` (local scope, default: the current folder). The installer detects Claude Code and OpenCode, merges its hooks into `settings.json` without touching your own, and records every file it created. Python 3.9 or newer is required.

Remove an installation with `--uninstall` (add `--scope local` or `--scope global` when both exist). Removing a local install leaves the project's `.forge` state, deliverables and memory untouched.

A local install can be committed (`.forge/kit`, `.claude`, `.opencode`) so teammates get the same Forge, or ignored in `.gitignore` to keep it personal. `forge kit verify` checks the kit and every installed copy against the hashes recorded at install time. Do not keep a global and a local install with hooks at once: the hooks would run twice.

## Phases

`bootstrap`, `landscape`, `compliance`, `prd`, `roadmap`, `design`, `architecture`, `rules`, `plans`, `build`, `validation`.

Every deliverable gets a review by `forge-qa` (what is missing) and by `forge-redteam` (what is contradictory) on its current version. The CLI refuses to advance a phase otherwise. Two modes: `interactive` (frequent questions) and `client` (questions only at touchpoints, progress reports in between); both run the same checks.

## Layout

- `cli/forge.py`: the single entry point for every state change (Python 3.9+, stdlib only).
- `skills/`: `forge` (router and golden rules), `forge-memory`, `forge-bootstrap`, `forge-compliance`, `forge-discover`, `forge-design`, `forge-architect`, `forge-rules`, `forge-plan`, `forge-build`.
- `agents/`: `forge` (orchestrator), `forge-qa`, `forge-redteam`, `forge-analyst`, `forge-compliance`, `forge-designer`, `forge-architect`, `forge-builder`, `forge-client-liaison`.
- `hooks/`: Claude Code hook script (wired into `settings.json` by the installer), OpenCode plugin (`opencode-forge.js`).
- `scripts/install.py`: the installer used by `install.sh` and `install.ps1`.
- `docs/`: status, improvements under study, escape-hatch audit, migration notes from v2.
- `tests/`: `e2e.sh`, `design.sh`, `flow.sh`, `adversarial.sh`, `rules.sh`, `rulesphase.sh`, `audit.sh`, `hooks.sh`, `templates.sh`, `compliance.sh`, `loops.sh`, `opencode_plugin.sh`, `install.sh`. Run all thirteen before every change.

## Quick check

```
for t in e2e design flow adversarial rules rulesphase audit hooks templates compliance loops opencode_plugin install; do bash tests/$t.sh || break; done
python3 cli/forge.py lint-rules $(find skills agents -name '*.md')
```

## Use

```
forge init --name MyApp --lang fr
forge status
```

The `forge` skill reads `forge status` and tells the agent what to do next. Start the work with the orchestrator agent: select the `forge` agent in OpenCode, or run `claude --agent forge` in Claude Code (not yet verified on a live install).
