#!/usr/bin/env bash
# End-to-end test of the Forge CLI. Usage: tests/e2e.sh   (exits non-zero on the first wrong result)
set -u
F="python3 $(cd "$(dirname "$0")/.." && pwd)/cli/forge.py"
T=$(mktemp -d); cd "$T"
ok()   { "$@" >/dev/null 2>&1 || { echo "FAIL (expected success): $*"; exit 1; }; }
fail() { "$@" >/dev/null 2>&1 && { echo "FAIL (expected refusal): $*"; exit 1; }; true; }
echo '{"findings":[{"id":"F1","severity":"critical","status":"open","evidence":"x"}]}' > bad.json
echo '{"findings":[{"id":"F1","severity":"minor","status":"open","evidence":"x"}]}' > ok.json
review_all() { for ag in qa redteam; do ok $F review "$1" --agent $ag --report ok.json; done; }
ok $F init --name Demo --lang fr
echo x > .forge/prd.md
fail $F register prd .forge/prd.md                 # premature artifact (no phase started)
fail $F phase start landscape                      # order
ok   $F phase start bootstrap
echo contract > .forge/contract.md; echo conv > .forge/conventions.md
ok $F register contract .forge/contract.md; ok $F register conventions .forge/conventions.md
fail $F gate check                                 # no reviews
fail $F review contract --agent qa --report bad.json   # blocking finding
review_all contract; review_all conventions
ok   $F gate check
fail $F gate approve                               # no evidence
fail $F gate approve --evidence auto               # interactive mode forbids auto
ok   $F gate approve --evidence "approved"
ok   $F phase start landscape
echo "L" > .forge/landscape.md; ok $F register landscape .forge/landscape.md; review_all landscape
echo more >> .forge/landscape.md
fail $F review landscape --agent qa --report ok.json   # stale
ok $F register landscape .forge/landscape.md; review_all landscape
ok $F mode client
ok $F gate approve --evidence auto                 # landscape is not a client touchpoint
ok $F phase start prd
echo "P" > .forge/prd.md; ok $F register prd .forge/prd.md; review_all prd
fail $F gate approve --evidence auto               # prd is a touchpoint
ok   $F gate approve --evidence "Yes, validated"
echo "{{TOKEN}}" > .forge/roadmap.md; ok $F phase start roadmap
fail $F register roadmap .forge/roadmap.md         # placeholder
ok $F memory checkpoint --task t --next n; ok $F memory decide --text d; ok $F memory learn --text l
ok $F lint-rules "$(cd "$(dirname "$0")" 2>/dev/null; pwd)/../skills"
echo "ALL PASS"
