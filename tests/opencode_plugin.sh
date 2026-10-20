#!/usr/bin/env bash
# The OpenCode plugin must never throw by accident (a throwing hook aborts the wrapped operation), must stay silent
# outside Forge projects, must inject memory at compaction, and must block a repeated subagent launch on purpose.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
command -v node >/dev/null 2>&1 || { echo "OPENCODE PLUGIN SKIPPED (node not installed)"; exit 0; }
W=$(mktemp -d); P=$(mktemp -d); N=$(mktemp -d)
F="python3 $ROOT/cli/forge.py"
( cd $P && $F init --name O >/dev/null && $F memory checkpoint --task "write the brief" --next "register brief" >/dev/null )
mk() { sed -e "s#const PYTHON = \"python3\"#const PYTHON = \"$1\"#" -e "s#const CLI = \".forge/kit/cli/forge.py\"#const CLI = \"$2\"#" -e "s#const TIMEOUT_MS = 10000#const TIMEOUT_MS = ${3:-10000}#" $ROOT/hooks/opencode-forge.js > $W/$4.mjs; }
mk python3 $ROOT/cli/forge.py 10000 good; mk nonexistent-python $ROOT/cli/forge.py 10000 nopython; mk python3 /no/such/forge.py 10000 nocli
printf 'import time\ntime.sleep(30)\n' > $W/slow.py; mk python3 $W/slow.py 700 slow
cat > $W/run.mjs <<'JS'
const [,, which, project, scenario] = process.argv
const { ForgePlugin } = await import(`${process.env.W}/${which}.mjs`)
const hooks = await ForgePlugin({ directory: project })
const fail = (m) => { console.log("FAIL: " + m); process.exit(1) }
if (scenario === "compact") {
  const out = { context: [] }
  await hooks["experimental.session.compacting"]({}, out)          // must never throw
  console.log(JSON.stringify(out.context))
} else if (scenario === "launch") {
  let blocked = 0, n = 0
  for (let i = 0; i < 4; i++) {
    try { await hooks["tool.execute.before"]({ tool: "task" }, { args: { subagent_type: "forge-qa", prompt: "review the prd" } }); n++ }
    catch (e) { blocked++; if (!/loop guard/.test(e.message)) fail("unexpected error " + e.message) }
  }
  console.log(`allowed=${n} blocked=${blocked}`)
} else if (scenario === "other-tools") {
  for (const tool of ["edit", "write", "bash", "read"]) await hooks["tool.execute.before"]({ tool }, { args: { command: "ls" } })
  await hooks["tool.execute.before"](undefined, undefined)          // malformed input must not throw
  console.log("ok")
}
JS
export W
chk() { out=$(node $W/run.mjs "$@" 2>&1) || { echo "FAIL: plugin threw: $*"; echo "$out"; exit 1; }; echo "$out"; }
out=$(chk good $P compact); echo "$out" | grep -q "write the brief" || { echo "FAIL: memory not injected at compaction: $out"; exit 1; }
out=$(chk good $N compact); [ "$out" = "[]" ] || { echo "FAIL: plugin acted outside a Forge project: $out"; exit 1; }
out=$(chk nopython $P compact); [ "$out" = "[]" ] || { echo "FAIL: missing python must be silent: $out"; exit 1; }
out=$(chk nocli $P compact);    [ "$out" = "[]" ] || { echo "FAIL: missing CLI must be silent: $out"; exit 1; }
start=$(date +%s); out=$(chk slow $P compact); [ "$out" = "[]" ] || { echo "FAIL: slow CLI must be cut off: $out"; exit 1; }
[ $(( $(date +%s) - start )) -lt 8 ] || { echo "FAIL: the hook waited for a hung CLI"; exit 1; }
out=$(chk good $P launch); [ "$out" = "allowed=2 blocked=2" ] || { echo "FAIL: loop guard: $out"; exit 1; }       # third identical launch is blocked
( cd $P && $F mode client --evidence "the user asked for client mode" >/dev/null )                                # progress in the state resets the count
out=$(chk good $P launch); [ "$out" = "allowed=2 blocked=2" ] || { echo "FAIL: loop guard after progress: $out"; exit 1; }
out=$(chk good $N launch); [ "$out" = "allowed=4 blocked=0" ] || { echo "FAIL: guard acted outside a Forge project: $out"; exit 1; }
out=$(chk good $P other-tools); [ "$out" = "ok" ] || { echo "FAIL: other tools: $out"; exit 1; }
echo "OPENCODE PLUGIN PASS"
