#!/usr/bin/env bash
# The compliance phase: every shortcut around a sourced, decided register is refused; obligations flow into the PRD.
set -u
CLIDIR="$(cd "$(dirname "$0")/.." && pwd)/cli"; export CLIDIR
F="python3 $CLIDIR/forge.py"
T=$(mktemp -d); cd "$T"
ok()   { "$@" >/dev/null 2>&1 || { echo "FAIL (expected success): $*"; exit 1; }; }
fail() { "$@" >/dev/null 2>&1 && { echo "FAIL (expected refusal): $*"; exit 1; }; true; }
blocked() { out=$($F gate check 2>&1); echo "$out" | grep -q "$1" || { echo "FAIL: expected '$1' in the gate output:"; echo "$out"; exit 1; }; }
rv() { $F review begin "$1" --agent "$2" >/dev/null 2>&1 || return 1; mkdir -p .forge/reviews; echo '{"findings":[]}' > ".forge/reviews/${1//:/_}.$2.json"; $F review record "$1" --agent "$2" --report ".forge/reviews/${1//:/_}.$2.json" >/dev/null; }
doc() { $F template "$1" | sed 's/<fill>/sample text/' > "$2"; python3 - "$2" "${3:-}" "${4:-}" <<'P'
import sys,re
p,a,b=sys.argv[1:4]; t=open(p).read()
if a: t=re.sub(r"(^## [^\n]*\n)", lambda m: m.group(1)+a.replace("\\n","\n")+"\n", t, count=1, flags=re.M)
if b: t=t.rstrip("\n")+"\n"+b.replace("\\n","\n")+"\n"
open(p,"w").write(t)
P
}
mut() { python3 -c "
import os,sys; sys.path.insert(0,os.environ['CLIDIR']); import forge
R=forge.find_root(); s=forge.load(R)
$1
forge.save(R,s)"; }
TODAY=$(date +%F); OLD=$(date -d '400 days ago' +%F)
H='- markets: TG, US-CA\n- topics: payments, subscriptions\n- max-age-days: 180'
R1="| OB-001 | TG | payments are processed | secure the payment data of users | https://example.org/law-a | $TODAY | applies | not-needed | - |"
R2="| OB-002 | US-CA | subscriptions renew automatically | cancelling is as easy as signing up | https://example.org/law-b | $TODAY | applies | risk-accepted | D-001 |"
reg() { doc compliance-register .forge/compliance-register.md "$H\n$1"; ok $F register compliance-register .forge/compliance-register.md; rv compliance-register qa; rv compliance-register redteam; }
ok $F init --name C
mut 's["phases"]["bootstrap"]="approved"; s["phases"]["landscape"]="approved"'
fail $F phase start prd                                    # compliance comes first
ok   $F phase start compliance
fail $F gate check                                         # no register
ok $F memory decide --text "Owner accepts the risk of shipping without a lawyer review for OB-002" --user-evidence "Owner wrote: go ahead without review"
reg "$R1\n$R2"; ok $F gate check                           # sound register
reg "$R1\n${R2/applies | risk-accepted/unknown | risk-accepted}"; blocked "still unknown"   # unknown applicability
reg "$R1\n| OB-002 | US-CA | subscriptions renew automatically | cancelling is as easy as signing up | https://example.org/law-b | $OLD | applies | risk-accepted | D-001 |"; blocked "days ago"   # stale source
reg "$R1\n${R2/https:\/\/example.org\/law-b/a blog post}"; blocked "source must be"   # not a URL
reg "$R1\n${R2/risk-accepted | D-001/risk-accepted | D-099}"; blocked "needs a decision"   # decision does not exist
reg "$R1\n${R2/risk-accepted | D-001/required | -}"; blocked "legal review is required"   # legal review required, not done
reg "$R1\n${R2/applies | risk-accepted | D-001/not-applicable | not-needed | -}"; blocked "needs a decision"   # not-applicable without the owner's words
reg "$R1"; blocked "appears in no obligation row"   # topic subscriptions has no row
reg "$R1\n$R2" ; sed -i 's/markets: TG, US-CA/markets: TG, US-CA, FR/' .forge/compliance-register.md
ok $F register compliance-register .forge/compliance-register.md; rv compliance-register qa; rv compliance-register redteam
blocked "market FR has no obligation row"   # market FR has no row
reg "$R1\n$R2"; ok $F gate check
ok $F gate approve --evidence "register accepted"
# the PRD must carry every applicable obligation, and cite only real ones
ok $F phase start prd
prd() { doc prd .forge/prd.md "- B1 rule\n$1"; ok $F register prd .forge/prd.md; rv prd qa; rv prd redteam; }
prd "- L1 secure payment data (OB-001)"; blocked "covered by no legal requirement"   # OB-002 is covered by no L
prd "- L1 secure payment data (OB-001)\n- L2 cancel easily (OB-002)\n- L3 invented (OB-099)"; blocked "not an applicable obligation"   # OB-099 does not exist
prd "- L1 secure payment data (OB-001)\n- L2 cancel easily"; blocked "cites no obligation"   # L2 cites nothing
prd "- L1 secure payment data (OB-001)\n- L2 cancel easily (OB-002)"
blocked "compliance recheck missing"   # recheck missing
fail $F compliance recheck --phase prd --evidence "ok"     # evidence too short
ok   $F compliance recheck --phase prd --evidence "Checked the new features against payments and subscriptions: no new topic"
ok   $F gate check
# the register cannot change silently after approval; a change forces a new recheck
echo "- note" >> .forge/compliance-register.md
$F status 2>&1 | grep -q "DRIFT" || { echo "FAIL: register drift not reported"; exit 1; }
ok $F phase reopen compliance --reason "a new market was added to the brief"
ok $F register compliance-register .forge/compliance-register.md; rv compliance-register qa; rv compliance-register redteam
ok $F gate check; ok $F gate approve --evidence "register accepted again"
ok $F phase start prd 2>/dev/null || true
echo "COMPLIANCE PASS"
