#!/usr/bin/env bash
# End-to-end test of the Forge CLI. Usage: tests/e2e.sh   (exits non-zero on the first wrong result)
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
F="python3 $ROOT/cli/forge.py"
rv() { mkdir -p .forge/reviews; cp "$3" ".forge/reviews/${1//:/_}.$2.json"; $F review "$1" --agent "$2" --report ".forge/reviews/${1//:/_}.$2.json"; }
T=$(mktemp -d); cd "$T"
ok()   { "$@" >/dev/null 2>&1 || { echo "FAIL (expected success): $*"; exit 1; }; }
fail() { "$@" >/dev/null 2>&1 && { echo "FAIL (expected refusal): $*"; exit 1; }; true; }
echo '{"findings":[{"id":"F1","severity":"critical","status":"open","evidence":"x"}]}' > bad.json
echo '{"findings":[{"id":"F1","severity":"minor","status":"open","evidence":"x"}]}' > ok.json
review_all() { for ag in qa redteam; do ok rv "$1" $ag ok.json; done; }
ok $F init --name Demo --lang fr
echo x > .forge/prd.md
fail $F register prd .forge/prd.md                 # premature artifact (no phase started)
fail $F phase start landscape                      # order
ok   $F phase start bootstrap
echo contract > .forge/contract.md; echo conv > .forge/brief.md
ok $F register contract .forge/contract.md; ok $F register brief .forge/brief.md
fail $F gate check                                 # no reviews
fail rv contract qa bad.json   # blocking finding
review_all contract; review_all brief
ok   $F gate check
fail $F gate approve                               # no evidence
fail $F gate approve --evidence auto               # interactive mode forbids auto
ok   $F gate approve --evidence "approved"
ok   $F phase start landscape
echo "L" > .forge/landscape.md; ok $F register landscape .forge/landscape.md; review_all landscape
echo more >> .forge/landscape.md
fail rv landscape qa ok.json   # stale
ok $F register landscape .forge/landscape.md; review_all landscape
ok $F mode client --evidence "the user asked for client mode"
ok $F gate approve --evidence auto                 # landscape is not a client touchpoint
ok $F phase start prd
printf "## 3. Business rules\n- B1 rule\n" > .forge/prd.md; ok $F register prd .forge/prd.md; review_all prd
fail $F gate approve --evidence auto               # prd is a touchpoint
mkdir -p .forge/client; echo "Plain summary for the client" > .forge/client/prd-summary.md
echo '{"questions":[{"where":"B1","question":"what is B1?"}]}' > .forge/reviews/prd.client.json
fail $F gate approve --evidence "Yes, validated"                  # client mode: no liaison review yet
fail $F client review --phase prd --document .forge/client/prd-summary.md --report .forge/reviews/prd.client.json   # question unresolved
echo '{"questions":[{"where":"B1","question":"what is B1?","resolution":"explained in the summary"}]}' > .forge/reviews/prd.client.json
ok $F client review --phase prd --document .forge/client/prd-summary.md --report .forge/reviews/prd.client.json
echo "edited after review" >> .forge/client/prd-summary.md
fail $F gate approve --evidence "Yes, validated"                  # summary changed after the review
ok $F client review --phase prd --document .forge/client/prd-summary.md --report .forge/reviews/prd.client.json
ok   $F gate approve --evidence "Yes, validated"
echo "{{TOKEN}}" > .forge/roadmap.md; ok $F phase start roadmap
fail $F register roadmap .forge/roadmap.md         # placeholder
ok $F memory checkpoint --task t --next n; ok $F memory decide --text d; ok $F memory learn --text l
ok $F lint-rules $(find "$ROOT/skills" "$ROOT/agents" -name "*.md")
echo "ALL PASS"
