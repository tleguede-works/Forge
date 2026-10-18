#!/usr/bin/env bash
# Installed kit integrity: install into a fake HOME, tamper, verify, uninstall.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FH=$(mktemp -d); mkdir -p $FH/.claude $FH/.config/opencode
ok()   { "$@" >/dev/null 2>&1 || { echo "FAIL (expected success): $*"; exit 1; }; }
fail() { "$@" >/dev/null 2>&1 && { echo "FAIL (expected refusal): $*"; exit 1; }; true; }
ok env HOME=$FH FORGE_SRC=$ROOT sh $ROOT/install.sh
K="python3 $FH/.forge/cli/forge.py"
ok $K kit verify
echo "# tampered" >> $FH/.forge/skills/forge/SKILL.md
fail $K kit verify
cd $(mktemp -d); $K init --name K >/dev/null 2>&1
$K status 2>&1 | grep -q "KIT MODIFIED" || { echo "FAIL: status does not report the modified kit"; exit 1; }
$K phase start bootstrap >/dev/null 2>&1
echo c > .forge/contract.md; echo v > .forge/conventions.md
$K register contract .forge/contract.md >/dev/null; $K register conventions .forge/conventions.md >/dev/null
mkdir -p .forge/reviews; echo '{"findings":[]}' > .forge/reviews/contract.qa.json; for x in contract.redteam conventions.qa conventions.redteam; do cp .forge/reviews/contract.qa.json .forge/reviews/$x.json; done
for n in contract conventions; do for ag in qa redteam; do $K review $n --agent $ag --report .forge/reviews/$n.$ag.json >/dev/null; done; done
fail $K gate approve --evidence "approved"      # a modified kit cannot approve
ok env HOME=$FH python3 $FH/.forge/scripts/install.py --uninstall
[ ! -e $FH/.forge ] || { echo "FAIL: kit left behind"; exit 1; }
echo "INSTALL PASS"
