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
# --- loop guard: a subagent launched again and again with no progress in the state
L=$(mktemp -d); cd $L; $F init --name G >/dev/null
launch() { echo "{\"cwd\":\"$L\",\"tool_input\":{\"subagent_type\":\"forge-qa\",\"prompt\":\"$1\"}}" | $H pre-task 2>/tmp/launch.err; }
launch "review the prd"; [ $? -eq 0 ] || { echo "FAIL: first launch blocked"; exit 1; }
launch "review the prd"; [ $? -eq 0 ] || { echo "FAIL: second launch blocked"; exit 1; }
launch "review the roadmap"; [ $? -eq 0 ] || { echo "FAIL: a different request was blocked"; exit 1; }
launch "review the prd"; rc=$?
[ $rc -eq 2 ] && grep -q "loop guard" /tmp/launch.err || { echo "FAIL: third identical launch not blocked (rc=$rc)"; exit 1; }
$F mode client --evidence "the user asked for client mode" >/dev/null                          # progress: the state changed
launch "review the prd"; [ $? -eq 0 ] || { echo "FAIL: launch blocked after progress"; exit 1; }
out=$(echo "{\"cwd\":\"$N\",\"tool_input\":{\"prompt\":\"x\"}}" | $H pre-task; echo rc=$?); echo "$out" | grep -q "rc=0" || { echo "FAIL: guard acted outside a Forge project"; exit 1; }
# --- the same file edited again and again
edit() { echo "{\"cwd\":\"$L\",\"tool_input\":{\"file_path\":\"$1\"}}" | $H post-tool 2>/tmp/edit.err; }
for i in 1 2 3 4 5; do edit src/a.ts; [ $? -eq 0 ] || { echo "FAIL: edit $i of one file warned too early"; exit 1; }; done
edit src/a.ts; rc=$?; [ $rc -eq 2 ] && grep -q "edited 6 times" /tmp/edit.err || { echo "FAIL: sixth edit of one file did not warn (rc=$rc)"; exit 1; }
for i in 1 2 3 4 5; do edit src/b$i.ts; done                                                   # different files do not trigger it
edit src/c.ts; [ $? -eq 0 ] || { echo "FAIL: different files triggered the same-file warning"; exit 1; }
# --- a broken state must never make a hook crash the host
echo "{ not json" > $L/.forge/state.json
out=$(echo "{\"cwd\":\"$L\",\"tool_input\":{\"subagent_type\":\"x\",\"prompt\":\"y\"}}" | $H pre-task 2>&1; echo rc=$?); echo "$out" | grep -q "rc=[02]" || { echo "FAIL: hook crashed on a broken state: $out"; exit 1; }
echo "HOOKS PASS"
