# Forge

Gated, CLI-enforced workflow that turns an idea into a verified, code-ready plan. Works with Claude Code and OpenCode.

Status: **v3 rebuild in progress.** See `docs/STATUS.md` for what exists and what is pending.

## Layout

- `cli/forge.py`: the single entry point for every state change (Python 3.9+, stdlib only).
- `skills/`: `forge` (router and golden rules), `forge-memory` (memory and triggers).
- `agents/`: `forge` (orchestrator), `qa`, `redteam`.
- `hooks/`: Claude Code settings snippet, hook script, OpenCode plugin.
- `tests/e2e.sh`: end-to-end test of the CLI. Run it before every change.

## Quick check

```
bash tests/e2e.sh
python3 cli/forge.py lint-rules skills agents
```
