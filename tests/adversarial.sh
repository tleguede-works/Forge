#!/usr/bin/env bash
# Escape-hatch scenarios: every shortcut an agent could try must be refused.
set -u
CLIDIR="$(cd "$(dirname "$0")/.." && pwd)/cli"; export CLIDIR
F="python3 $CLIDIR/forge.py"
rv() { mkdir -p .forge/reviews; cp "$3" ".forge/reviews/${1//:/_}.$2.json"; $F review "$1" --agent "$2" --report ".forge/reviews/${1//:/_}.$2.json"; }
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
fail rv contract qa r1.json
echo '{"findings":[{"id":"A","severity":"blocker","status":"open","evidence":"x"}]}' > r2.json
fail rv contract qa r2.json
echo '{"findings":"none"}' > r3.json; fail rv contract qa r3.json
# 3. One reviewer only
ok rv contract qa clean.json; ok rv conventions qa clean.json
fail $F gate check
ok rv contract redteam clean.json; ok rv conventions redteam clean.json
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
ok rv contract qa clean.json; ok rv contract redteam clean.json
ok $F gate check; ok $F gate approve --evidence "approved"
# 8. Silent edit of an approved deliverable is reported and blocks the next phase
echo sneaky >> .forge/contract.md
fail $F phase start landscape
$F status 2>&1 | grep -q DRIFT || { echo "FAIL: drift not reported"; exit 1; }
# 9. Reopen is the only way back, and it needs a reason
fail $F phase reopen bootstrap --reason ""
ok $F phase reopen bootstrap --reason "contract changed after client call"
ok $F register contract .forge/contract.md
# 11. Mode switch without the user's words, and reviews not written at the contract path
fail $F mode client
echo '{"findings":[]}' > elsewhere.json
fail $F review contract --agent qa --report elsewhere.json
# 12. Report file edited after it was recorded
echo more >> .forge/contract.md; ok $F register contract .forge/contract.md
ok rv contract qa clean.json; ok rv contract redteam clean.json; ok rv conventions qa clean.json; ok rv conventions redteam clean.json
ok $F gate check
echo '{"findings":[],"note":"edited later"}' > .forge/reviews/contract.qa.json
fail $F gate check
# 13. Dismissing a finding needs a real decision entry
echo '{"findings":[{"id":"A","severity":"critical","status":"dismissed","evidence":"x","reason":"not important"}]}' > d1.json
fail rv contract qa d1.json
echo '{"findings":[{"id":"A","severity":"critical","status":"dismissed","evidence":"x","reason":"D-099"}]}' > d2.json
fail rv contract qa d2.json
ok $F memory decide --text "Finding A is out of scope: the client confirmed on 2026-10-18"
echo '{"findings":[{"id":"A","severity":"critical","status":"dismissed","evidence":"x","reason":"D-001"}]}' > d3.json
ok rv contract qa d3.json
# 10. Placeholders
echo "TODO later" > .forge/conventions.md; fail $F register conventions .forge/conventions.md
echo "ALL ADVERSARIAL PASS"
