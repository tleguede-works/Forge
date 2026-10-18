#!/usr/bin/env bash
# Escape-hatch scenarios: every shortcut an agent could try must be refused.
set -u
CLIDIR="$(cd "$(dirname "$0")/.." && pwd)/cli"; export CLIDIR
F="python3 $CLIDIR/forge.py"
T=$(mktemp -d); cd "$T"
ok()   { "$@" >/dev/null 2>&1 || { echo "FAIL (expected success): $*"; exit 1; }; }
fail() { "$@" >/dev/null 2>&1 && { echo "FAIL (expected refusal): $*"; exit 1; }; true; }
echo '{"findings":[]}' > clean.json
ok $F init --name Adv --lang en
ok $F phase start bootstrap
echo contract > .forge/contract.md; echo conv > .forge/conventions.md
ok $F register contract .forge/contract.md; ok $F register conventions .forge/conventions.md
# 1. Hand-edit state.json to approve the phase
python3 - <<'P'
import json; s=json.load(open(".forge/state.json")); s["phases"]["bootstrap"]="approved"; json.dump(s,open(".forge/state.json","w"))
P
fail $F status; fail $F phase start landscape; fail $F gate check
git_restore() { python3 - <<'P'
import json; s=json.load(open(".forge/state.json")); s["phases"]["bootstrap"]="in_progress"; json.dump(s,open(".forge/state.json","w"))
P
}
git_restore; ok $F status                           # putting the original content back is valid (same as git checkout)
# restore a clean state (simulates `git checkout`)
rm -rf .forge AGENTS.md; ok $F init --name Adv --lang en; ok $F phase start bootstrap
echo contract > .forge/contract.md; echo conv > .forge/conventions.md
ok $F register contract .forge/contract.md; ok $F register conventions .forge/conventions.md
# 2. Forged review report: dismissed finding with no reason, malformed severity
echo '{"findings":[{"id":"A","severity":"critical","status":"dismissed","evidence":"x"}]}' > r1.json
fail $F review contract --agent qa --report r1.json
echo '{"findings":[{"id":"A","severity":"blocker","status":"open","evidence":"x"}]}' > r2.json
fail $F review contract --agent qa --report r2.json
echo '{"findings":"none"}' > r3.json; fail $F review contract --agent qa --report r3.json
# 3. One reviewer only
ok $F review contract --agent qa --report clean.json; ok $F review conventions --agent qa --report clean.json
fail $F gate check
ok $F review contract --agent redteam --report clean.json; ok $F review conventions --agent redteam --report clean.json
ok $F gate check
# 4. Register a file outside .forge, or via a traversal path
echo x > outside.md; fail $F register contract outside.md; fail $F register contract ../outside.md
# 5. Skip: start a later phase, register a later deliverable early
fail $F phase start prd; fail $F phase start design; echo p > .forge/prd.md; fail $F register prd .forge/prd.md
# 6. Approve with empty / blank evidence
fail $F gate approve --evidence ""; fail $F gate approve --evidence " "
# 7. Edit a deliverable after the review: stale review blocks the gate
echo more >> .forge/contract.md; fail $F gate check
ok $F register contract .forge/contract.md; fail $F gate check   # reviews reset by the new hash
ok $F review contract --agent qa --report clean.json; ok $F review contract --agent redteam --report clean.json
ok $F gate check; ok $F gate approve --evidence "approved"
# 8. Silent edit of an approved deliverable is reported and blocks the next phase
echo sneaky >> .forge/contract.md
fail $F phase start landscape
$F status 2>&1 | grep -q DRIFT || { echo "FAIL: drift not reported"; exit 1; }
# 9. Reopen is the only way back, and it needs a reason
fail $F phase reopen bootstrap --reason ""
ok $F phase reopen bootstrap --reason "contract changed after client call"
ok $F register contract .forge/contract.md
# 10. Placeholders
echo "TODO later" > .forge/conventions.md; fail $F register conventions .forge/conventions.md
echo "ALL ADVERSARIAL PASS"
