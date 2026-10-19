# Forge

Gated, CLI-enforced workflow that turns an idea into a verified, code-ready plan, then builds it slice by slice. Works with Claude Code and OpenCode.

Status: **v3 rebuild in progress.** See `docs/STATUS.md` for what exists and what is pending, and `docs/IMPROVEMENTS.md` for the improvements under study.

## Install

Linux and macOS:

```
curl -fsSL https://raw.githubusercontent.com/tleguede-works/Forge/main/install.sh | sh
```

Windows (PowerShell):

```
irm https://raw.githubusercontent.com/tleguede-works/Forge/main/install.ps1 | iex
```

The installer detects Claude Code and OpenCode, installs skills, agents and hooks, and adds the `forge` command. Remove everything with `--uninstall`. Python 3.9 or newer is required.

## Phases

`bootstrap`, `landscape`, `prd`, `roadmap`, `design`, `architecture`, `rules`, `plans`, `build`, `validation`.

Every deliverable gets a review by `forge-qa` (what is missing) and by `forge-redteam` (what is contradictory) on its current version. The CLI refuses to advance a phase otherwise. Two modes: `interactive` (frequent questions) and `client` (questions only at touchpoints, progress reports in between); both run the same checks.

## Layout

- `cli/forge.py`: the single entry point for every state change (Python 3.9+, stdlib only).
- `skills/`: `forge` (router and golden rules), `forge-memory`, `forge-bootstrap`, `forge-discover`, `forge-design`, `forge-architect`, `forge-rules`, `forge-plan`, `forge-build`.
- `agents/`: `forge` (orchestrator), `forge-qa`, `forge-redteam`, `forge-analyst`, `forge-designer`, `forge-architect`, `forge-builder`, `forge-client-liaison`.
- `hooks/`: Claude Code hook script (wired into `settings.json` by the installer), OpenCode plugin.
- `scripts/install.py`: the installer used by `install.sh` and `install.ps1`.
- `docs/`: status, improvements under study, escape-hatch audit, migration notes from v2.
- `tests/`: `e2e.sh`, `design.sh`, `flow.sh`, `adversarial.sh`, `rules.sh`, `rulesphase.sh`, `audit.sh`, `hooks.sh`, `install.sh`. Run all nine before every change.

## Quick check

```
for t in e2e design flow adversarial rules rulesphase audit hooks install; do bash tests/$t.sh || break; done
python3 cli/forge.py lint-rules $(find skills agents -name '*.md')
```

## Use

```
forge init --name MyApp --lang fr
forge status
```

The `forge` skill reads `forge status` and tells the agent what to do next. Start the work with the orchestrator agent: select the `forge` agent in OpenCode, or run `claude --agent forge` in Claude Code (not yet verified on a live install).
