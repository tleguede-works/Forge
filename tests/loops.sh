#!/usr/bin/env bash
# Loop guard: the same review is never run twice on one version, repeated failures stop at five, escalation needs the user.
set -u
CLIDIR="$(cd "$(dirname "$0")/.." && pwd)/cli"; export CLIDIR
F="python3 $CLIDIR/forge.py"
T=$(mktemp -d); cd "$T"
ok()   { "$@" >/dev/null 2>&1 || { echo "FAIL (expected success): $*"; exit 1; }; }
fail() { "$@" >/dev/null 2>&1 && { echo "FAIL (expected refusal): $*"; exit 1; }; true; }
says() { local pat="$1"; shift; out=$("$@" 2>&1); echo "$out" | grep -q "$pat" || { echo "FAIL: expected '$pat' from: $*"; echo "$out"; exit 1; }; }
code() { "$@" >/dev/null 2>&1; echo $?; }
doc() { $F template "$1" | sed 's/<fill>/sample text/' > "$2"; }
bump() { echo "- change $RANDOM" >> .forge/contract.md; $F register contract .forge/contract.md >/dev/null; }
report() { mkdir -p .forge/reviews; echo "$1" > ".forge/reviews/contract.$2.json"; }
A1='The gate refuses because no review exists for the deliverables; I kept re-running the gate instead of launching the two reviewers once each through the review flow.'
A2='The same refusal came back after the new approach; the reviews cannot be produced without information that only the owner has, so repeating the gate changes nothing.'
A3='Three rounds ended with the same pricing gap which the files cannot answer, so more review rounds change nothing until the owner gives the price.'
CLEAN='{"findings":[]}'
BLOCK='{"findings":[{"id":"F1","severity":"critical","status":"open","evidence":"price missing"}]}'
ASK='{"findings":[{"id":"F2","severity":"major","status":"open","needs":"user","evidence":"the payment provider is not named anywhere"}]}'
ok $F init --name Loop
ok $F phase start bootstrap
# --- 1. NEEDS-USER refusals are named as such
says "NEEDS-USER" $F mode client
# --- 2. five identical failures stop the operation; one success in between resets the count
for i in 1 2 3 4; do fail $F gate check; done
says "no failing operation\|gate:check:bootstrap: 4 identical" $F attempts
doc contract .forge/contract.md; ok $F register contract .forge/contract.md      # progress: the refusal text changes
for i in 1 2 3 4; do fail $F gate check; done
$F attempts | grep -q "STUCK" && { echo "FAIL: stuck although the failure changed and counts restarted"; exit 1; }
doc brief .forge/brief.md; ok $F register brief .forge/brief.md
for i in 1 2 3 4 5; do fail $F gate check; done                                   # reviews are missing: the same refusal five times
[ "$(code $F gate check)" -eq 3 ] || { echo "FAIL: the sixth identical attempt is not stopped with code 3"; exit 1; }
says "STUCK" $F gate check
says "STUCK" $F status
says "gate:check:bootstrap" $F attempts
# --- 3. unstick needs a real analysis; the second time it needs the user
fail $F unstick gate:check:bootstrap --analysis "it fails"
fail $F unstick gate:check:bootstrap --analysis "$(printf 'x%.0s' $(seq 1 130))"                      # no new approach
ok   $F unstick gate:check:bootstrap --analysis "$A1" --new-approach "launch each reviewer once through forge review begin, then record the reports"
grep -q "STUCK gate:check:bootstrap" .forge/memory/lessons.md || { echo "FAIL: the analysis is not kept as a lesson"; exit 1; }
for i in 1 2 3 4 5; do fail $F gate check; done
says "NEEDS-USER" $F unstick gate:check:bootstrap --analysis "$A2" --new-approach "a different approach that is long enough to pass the length check"
ok   $F unstick gate:check:bootstrap --analysis "$A2" --user-answer "Owner: launch the reviewers now"
# --- 4. a reviewer is never run twice on the same version
ok $F review begin contract --agent qa
report "$CLEAN" qa; ok $F review record contract --agent qa --report .forge/reviews/contract.qa.json
says "already reviewed this exact version" $F review begin contract --agent qa
# --- 5. a recorded report needs a launch, and a launch has a limited number of retries
bump; fail $F review record contract --agent qa --report .forge/reviews/contract.qa.json
ok $F review begin contract --agent qa; ok $F review begin contract --agent qa
says "launched 2 times" $F review begin contract --agent qa
# --- 6. a finding only the user can settle is reported as such
bump; ok $F review begin contract --agent redteam; report "$ASK" redteam
says "NEEDS-USER" $F review record contract --agent redteam --report .forge/reviews/contract.redteam.json
# --- 7. three blocked rounds escalate to the user, who must answer before a fourth
bump; ok $F review begin contract --agent qa; report "$BLOCK" qa; fail $F review record contract --agent qa --report .forge/reviews/contract.qa.json
bump; ok $F review begin contract --agent qa; report "$BLOCK" qa; fail $F review record contract --agent qa --report .forge/reviews/contract.qa.json
bump
[ "$(code $F review begin contract --agent qa)" -eq 3 ] || { echo "FAIL: the fourth blocked round is not escalated"; exit 1; }
says "ESCALATE" $F review begin contract --agent redteam
says "rounds:contract" $F attempts
says "NEEDS-USER" $F unstick rounds:contract --analysis "$A3" --new-approach "ask the owner for the price and add it to the contract before the next round"
ok   $F unstick rounds:contract --analysis "$A3" --user-answer "Owner: the price is fixed at 4000 EUR"
bump; ok $F review begin contract --agent qa
echo "LOOPS PASS"
