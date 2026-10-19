#!/usr/bin/env bash
# Regression tests for the holes found by the audit of 2026-10-19.
set -u
CLIDIR="$(cd "$(dirname "$0")/.." && pwd)/cli"; export CLIDIR
F="python3 $CLIDIR/forge.py"
doc() { $F template "$1" | sed 's/<fill>/sample text/' > "$2"; python3 - "$2" "${3:-}" "${4:-}" <<'P'
import sys,re
p,a,b=sys.argv[1:4]; t=open(p).read()
if a: t=re.sub(r"(^## [^\n]*\n)", lambda m: m.group(1)+a.replace("\\n","\n")+"\n", t, count=1, flags=re.M)
if b: t=t.rstrip("\n")+"\n"+b.replace("\\n","\n")+"\n"
open(p,"w").write(t)
P
}
T=$(mktemp -d); cd "$T"
ok()   { "$@" >/dev/null 2>&1 || { echo "FAIL (expected success): $*"; exit 1; }; }
fail() { "$@" >/dev/null 2>&1 && { echo "FAIL (expected refusal): $*"; exit 1; }; true; }
mut() { python3 -c "
import os,sys; sys.path.insert(0,os.environ['CLIDIR']); import forge
R=forge.find_root(); s=forge.load(R)
$1
forge.save(R,s)"; }
ok $F init --name Audit
# 1. Deliverable names have a closed shape (no path tricks into the review folder)
mut 'for p in forge.PHASES[:forge.PHASES.index("design")]: s["phases"][p]="approved"
s["phases"]["design"]="in_progress"; s["phase"]["current"]="design"'
echo "enough body text here" > .forge/x.md
fail $F register "screen:../../../outside" .forge/x.md
fail $F register "screen:home" .forge/x.md
fail $F register "Plan:S1" .forge/x.md
ok   $F register "screen:SCR-001" .forge/x.md
# 2. The next action matches the phase (plans and build)
mut 's["phases"]["design"]="approved"; s["phases"]["architecture"]="approved"; s["phases"]["rules"]="approved"
s["phases"]["plans"]="in_progress"; s["phase"]["current"]="plans"'
printf '| id | name | module | serves |\n|---|---|---|---|\n| S01 | Pay | billing | B1 |\n' > .forge/slices.md
$F status | grep -q "plan:S01" || { echo "FAIL: plans next action does not name plan:S01"; exit 1; }
mut 's["phases"]["plans"]="approved"; s["phases"]["build"]="in_progress"; s["phase"]["current"]="build"'
$F status | grep -q "forge slice start S01" || { echo "FAIL: build next action does not name the slice"; exit 1; }
# 3. PRD ids: unique, never reused
D=$(mktemp -d); cd $D; ok $F init --name P
mut 's["phases"]["bootstrap"]="approved"; s["phases"]["landscape"]="approved"; s["phases"]["compliance"]="approved"; s["phases"]["prd"]="in_progress"; s["phase"]["current"]="prd"'
rv() { mkdir -p .forge/reviews; echo '{"findings":[]}' > ".forge/reviews/$1.$2.json"; $F review "$1" --agent "$2" --report ".forge/reviews/$1.$2.json"; }
doc prd .forge/prd.md "- B1 first\n- B1 second"
ok $F register prd .forge/prd.md; rv prd qa >/dev/null; rv prd redteam >/dev/null
fail $F gate check                                          # duplicated id
doc prd .forge/prd.md "- B1 first" "- B1 withdrawn: reason"
ok $F register prd .forge/prd.md; rv prd qa >/dev/null; rv prd redteam >/dev/null
fail $F gate check                                          # id both live and withdrawn
doc prd .forge/prd.md
ok $F register prd .forge/prd.md; rv prd qa >/dev/null; rv prd redteam >/dev/null
fail $F gate check                                          # no id at all
doc prd .forge/prd.md "- B1 first\n- E1 edge"
ok $F register prd .forge/prd.md; rv prd qa >/dev/null; rv prd redteam >/dev/null
ok $F gate check
# 4. Roadmap covers every live requirement and invents none
mut 's["phases"]["prd"]="approved"; s["phases"]["roadmap"]="in_progress"; s["phase"]["current"]="roadmap"'
doc roadmap .forge/roadmap.md "- Pay: B1"
ok $F register roadmap .forge/roadmap.md; rv roadmap qa >/dev/null; rv roadmap redteam >/dev/null
fail $F gate check                                          # E1 appears nowhere
doc roadmap .forge/roadmap.md "- Pay: B1, E1, V9"
ok $F register roadmap .forge/roadmap.md; rv roadmap qa >/dev/null; rv roadmap redteam >/dev/null
fail $F gate check                                          # V9 does not exist
doc roadmap .forge/roadmap.md "- Pay: B1, E1"
ok $F register roadmap .forge/roadmap.md; rv roadmap qa >/dev/null; rv roadmap redteam >/dev/null
ok $F gate check
echo "AUDIT PASS"
