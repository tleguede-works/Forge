#!/usr/bin/env bash
# The rules phase: the gate runs the rule-set audit; approved rule files are protected against silent edits.
set -u
CLIDIR="$(cd "$(dirname "$0")/.." && pwd)/cli"; export CLIDIR
F="python3 $CLIDIR/forge.py"
T=$(mktemp -d); cd "$T"
ok()   { "$@" >/dev/null 2>&1 || { echo "FAIL (expected success): $*"; exit 1; }; }
fail() { "$@" >/dev/null 2>&1 && { echo "FAIL (expected refusal): $*"; exit 1; }; true; }
rv() { mkdir -p .forge/reviews; echo '{"findings":[]}' > ".forge/reviews/${1//:/_}.$2.json"; $F review "$1" --agent "$2" --report ".forge/reviews/${1//:/_}.$2.json"; }
ok $F init --name RP
mkdir -p .opencode/rules
echo '{"dependencies":{"react":"18.3.1"}}' > package.json
echo '{"instructions":["AGENTS.md",".opencode/rules/*.md"]}' > opencode.json
cat >> AGENTS.md <<'E'
# Project
| File | Owns |
|---|---|
| `quality-gates.md` | commands and thresholds |
| `coding.md` | code conventions |
Priorities: correctness, then security, then speed. See `quality-gates.md` §Gates.
E
cat > .opencode/rules/quality-gates.md <<'E'
# Quality gates
## Gates
| Gate | Command | Passes when |
|---|---|---|
| lint | `npm run lint` | exit 0 |
| typecheck | `npm run typecheck` | exit 0 |
| tests | `npm test` | exit 0 |
| coverage | `npm run coverage -- --threshold 80` | coverage 80% |
| duplication | `npx jscpd src --threshold 3` | duplication 3% |
| vulnerabilities | `npm audit --audit-level=high` | exit 0 |
| review | `npm run review-check` | exit 0 |
E
printf '# Coding\nSplit a file by responsibility.\n' > .opencode/rules/coding.md
python3 - <<'P'
import os,sys; sys.path.insert(0,os.environ["CLIDIR"]); import forge
R=forge.find_root(); s=forge.load(R)
for p in forge.PHASES[:forge.PHASES.index("rules")]: s["phases"][p]="approved"
forge.save(R,s)
P
fail $F phase start plans                         # rules phase is not approved
ok   $F phase start rules
fail $F register plan:S01 .forge/x.md             # a plan is not a rules-phase deliverable
fail $F gate check                                # no report yet
printf '# Rules report\n- target: opencode\n- budget: 800\nTemplates selected: react (package.json lists react)\n' > .forge/rules-report.md
ok $F register rules-report .forge/rules-report.md
rv rules-report qa; rv rules-report redteam
ok $F gate check
echo 'You should keep it clean.' >> .opencode/rules/coding.md
fail $F gate check                                # the gate runs the audit: soft wording
printf '# Coding\nSplit a file by responsibility.\n' > .opencode/rules/coding.md
ok $F gate check
sed -i 's/budget: 800/budget: 10/' .forge/rules-report.md
ok $F register rules-report .forge/rules-report.md; rv rules-report qa; rv rules-report redteam
fail $F gate check                                # the report's own budget is enforced
sed -i 's/budget: 10/budget: 800/' .forge/rules-report.md
ok $F register rules-report .forge/rules-report.md; rv rules-report qa; rv rules-report redteam
ok $F gate approve --evidence "rules accepted"
# approved rule files are protected
echo "Name tests after behavior." >> .opencode/rules/coding.md
$F status 2>&1 | grep -q "DRIFT: rule files changed" || { echo "FAIL: rules drift not reported"; exit 1; }
fail $F phase start plans
ok $F phase reopen rules --reason "added a naming rule to coding.md"
ok $F gate check
ok $F gate approve --evidence "rules accepted again"
ok $F phase start plans
echo "RULES PHASE PASS"
