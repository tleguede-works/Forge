#!/usr/bin/env bash
# The Claude Code hook script: silent outside a Forge project, restores memory at session start, asks for a checkpoint every 10 edits.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
H="python3 $ROOT/hooks/forge_hook.py"; F="python3 $ROOT/cli/forge.py"
P=$(mktemp -d); N=$(mktemp -d)
cd $P; $F init --name H >/dev/null
$F memory checkpoint --task "write the brief" --next "register brief" >/dev/null
out=$(echo "{\"cwd\":\"$P\"}" | $H session-start); echo "$out" | grep -q "write the brief" || { echo "FAIL: session-start does not restore NOW.md"; exit 1; }
out=$(echo "{\"cwd\":\"$N\"}" | $H session-start); [ -z "$out" ] || { echo "FAIL: hook is not silent outside a Forge project"; exit 1; }
echo "{\"cwd\":\"$P\"}" | $H pre-compact; grep -q "compaction" $P/.forge/memory/journal.md || { echo "FAIL: pre-compact is not journaled"; exit 1; }
for i in $(seq 1 9); do echo "{\"cwd\":\"$P\"}" | $H post-tool; [ $? -eq 0 ] || { echo "FAIL: edit $i asked for a checkpoint too early"; exit 1; }; done
echo "{\"cwd\":\"$P\"}" | $H post-tool 2>/tmp/hook.err; rc=$?
[ $rc -eq 2 ] && grep -q "forge memory checkpoint" /tmp/hook.err || { echo "FAIL: edit 10 does not ask for a checkpoint (rc=$rc)"; exit 1; }
echo "{\"cwd\":\"$P\"}" | $H post-tool; [ $? -eq 0 ] || { echo "FAIL: counter not reset after the request"; exit 1; }
for i in $(seq 1 9); do echo "{\"cwd\":\"$P\"}" | $H post-tool; done
$F memory checkpoint --task t --next n >/dev/null
echo "{\"cwd\":\"$P\"}" | $H post-tool; [ $? -eq 0 ] || { echo "FAIL: a checkpoint does not reset the edit counter"; exit 1; }
echo "HOOKS PASS"
