#!/usr/bin/env bash
# Tests of coverage, premises, plans, slices, reopen and client commands.
set -u
CLIDIR="$(cd "$(dirname "$0")/.." && pwd)/cli"; export CLIDIR
F="python3 $CLIDIR/forge.py"
T=$(mktemp -d); cd "$T"; $F init --name Flow >/dev/null
ok()   { "$@" >/dev/null 2>&1 || { echo "FAIL (expected pass): $*"; exit 1; }; }
fail() { "$@" >/dev/null 2>&1 && { echo "FAIL (expected refusal): $*"; exit 1; }; true; }
cat > .forge/prd.md <<'P'
# PRD
## 3. Business rules
- B1 Users pay by card
- B2 Refund within 14 days
## 4. Edge cases
- E1 Card declined
## 9. Out of scope
- B3 Multi-tenant: dropped, no second client
P
cat > .forge/slices.md <<'S'
| id | name | module | serves |
|---|---|---|---|
| S01 | Pay | billing | B1,E1 |
S
fail $F check coverage                              # B2 served by no slice
sed -i 's/B1,E1/B1,B2,E1/' .forge/slices.md; ok $F check coverage
sed -i 's/B1,B2,E1/B1,B2,E1,B3/' .forge/slices.md; fail $F check coverage   # serves a withdrawn requirement
sed -i 's/,B3//' .forge/slices.md
# premises: a deliverable depending on a withdrawn requirement
python3 - <<'P'
import os,sys;sys.path.insert(0,os.environ["CLIDIR"]);import forge;R=forge.find_root();s=forge.load(R)
s["deliverables"]["brief"]={"path":".forge/prd.md","phase":"bootstrap","hash":"x","requires":["B3"],"reviews":{}}
forge.save(R,s)
P
fail $F check premises
python3 - <<'P'
import os,sys;sys.path.insert(0,os.environ["CLIDIR"]);import forge;R=forge.find_root();s=forge.load(R); s["deliverables"]["brief"]["requires"]=["B1"]; forge.save(R,s)
P
ok $F check premises
# plans
mkdir -p .forge/plans
python3 - <<'P'
import os,sys;sys.path.insert(0,os.environ["CLIDIR"]);import forge;R=forge.find_root();s=forge.load(R)
for n,p in (("plan:S01",".forge/plans/S01.md"),("plans-index",".forge/plans/index.md"),("test-plan",".forge/test-plan.md")):
    s["deliverables"][n]={"path":p,"phase":"plans","hash":"x","requires":[],"reviews":{}}
forge.save(R,s)
P
echo "S01" > .forge/plans/index.md
printf '# S01\n## Serves\n- serves: B1,B2,E1\n## Tasks\n- [ ] T1 do\n## Acceptance\nx\n## Test cases\n- TC-S01-1 pays\n' > .forge/plans/S01.md
printf 'S01 covers B1 B2 E1\n' > .forge/test-plan.md
ok $F check plans
printf 'S01 covers B1 E1\n' > .forge/test-plan.md; fail $F check plans       # B2 untested
printf 'S01 covers B1 B2 E1\n' > .forge/test-plan.md
sed -i 's/- TC-S01-1 pays//' .forge/plans/S01.md; fail $F check plans         # no test case
python3 - <<'P'
t=open(".forge/plans/S01.md").read().replace("- [ ] T1 do","\n".join(f"- [ ] T{i} do" for i in range(1,17)))+"- TC-S01-1 pays\n"
open(".forge/plans/S01.md","w").write(t)
P
fail $F check plans                                                          # 16 tasks
# slices flow and reopen
python3 - <<'P'
import os,sys;sys.path.insert(0,os.environ["CLIDIR"]);import forge;R=forge.find_root();s=forge.load(R)
for p in ["bootstrap","landscape","compliance","prd","roadmap","design","architecture","rules","plans"]: s["phases"][p]="approved"
s["phases"]["build"]="in_progress"; s["phase"]["current"]="build"; forge.save(R,s)
P
ok $F slice start S01
fail $F slice done S01 --evidence "tests pass"
ok $F slice done S01 --evidence "pytest tests/test_pay.py : 4 passed"
ok $F gate check
ok $F phase reopen prd --reason "client added refunds, B2 changed"
fail $F phase reopen prd --reason "again twice"                             # already in progress
fail $F phase start roadmap                                                  # prd not approved after reopen
# client points
fail $F client ask --what "Pick payment provider"
ok $F client ask --what "Pick payment provider" --price "49 EUR/month" --by 2020-01-01 --if-no-answer "use Stripe"
ok $F client list; ok $F client sweep
fail $F client resolve --id 1 --answer x                                    # already decided by default
ok $F client ask --what "Choose a logo" --price "free" --by 2099-01-01 --if-no-answer "keep the draft"
out=$($F client report) || { echo "FAIL: client report"; exit 1; }
echo "$out" | grep -q "points waiting for the client: 1" || { echo "FAIL: report misses the pending point"; exit 1; }
echo "$out" | grep -q "decided by default (must be reported): 1" || { echo "FAIL: report misses the default decision"; exit 1; }
out2=$($F client report); echo "$out2" | grep -q "decided by default (must be reported): 0" || { echo "FAIL: default decision reported twice"; exit 1; }
echo "FLOW PASS"
