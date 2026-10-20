# OpenCode hooks: why they crashed, and what changed

Reported symptom: the OpenCode hooks crash the system. No logs were available, so this analysis rests on the official documentation (OpenCode plugin docs and Bun shell docs, read through Context7 on 2026-10-20) and on the code of the first plugin. It is a diagnosis by reading, not by reproduction.

## Causes

| # | Cause | Evidence | Effect |
|---|---|---|---|
| 1 | The `tool.execute.after` hook ran `forge memory log` through Bun's `$` with `.quiet()` but without `.nothrow()` and without `try/catch` | Bun's shell throws a `ShellError` on any non-zero exit code. The OpenCode docs show that a throw inside a tool hook propagates and stops the operation (their example blocks a read of `.env` by throwing in `tool.execute.before`) | The command fails whenever the project is not a Forge project (exit 1, no `.forge/state.json`), when `forge` is not on the PATH (exit 127), or when the relative path of a local install does not resolve. The error surfaces inside OpenCode on the 10th edit |
| 2 | The plugin was installed globally and acted in every project | The hook counted edits everywhere | A user with a global install met the failure in projects that never used Forge |
| 3 | The plugin file went to `plugin/`; the current docs name `plugins/` | OpenCode docs: plugins load from `.opencode/plugins/` and `~/.config/opencode/plugins/` | Depending on the version the file was ignored or loaded through a legacy path |
| 4 | The command was run with no timeout | `$` waits for the process | A hung CLI would freeze compaction |
| 5 | The edit-threshold hook did nothing useful | It wrote a journal line the model never saw | Risk with no benefit |
| 6 | `experimental.session.compacting` is marked experimental | OpenCode docs | The hook can change between versions; the plugin must tolerate absence and a different shape |

## What changed (`hooks/opencode-forge.js`)

- Every hook catches its own errors. The only deliberate throw is the loop guard, which blocks the third identical subagent launch while the Forge state is unchanged.
- Commands run through `node:child_process` `execFileSync` with a 10 second timeout and no shell, so a failing or hung command returns an empty string.
- The plugin acts only when `.forge/state.json` exists in the project directory.
- The dead edit counter is removed. The plugin now does two things: inject `forge memory resume` into the compaction summary, and guard repeated subagent launches.
- The file is installed as `plugins/forge.js`; an earlier `plugin/forge.ts` is removed on install.
- Plain JavaScript with no type import, so nothing depends on `@opencode-ai/plugin` resolving.

## Tested (`tests/opencode_plugin.sh`, run with Node)

A missing Python, a missing CLI, a CLI that hangs (cut off after 700 ms in the test), a directory that is not a Forge project, malformed hook input, and every tool other than `task`: none of them throws. Compaction injects the project memory. The third identical launch is blocked, and an unchanged-state counter resets when the state changes.

## Not verified

- Never run inside a real OpenCode. The hook names and signatures come from its documentation.
- The subagent tool is assumed to be named `task` with `subagent_type` and `prompt` arguments.
- If a crash persists, the useful facts are the OpenCode version, the exact error text, and which hook is named in it. The plugin can be disabled by deleting `plugins/forge.js` without touching the rest of Forge.
