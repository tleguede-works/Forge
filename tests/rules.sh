#!/usr/bin/env bash
# `forge rules audit`: a sound rule set passes all ten checks; one mutation per check fails exactly that check.
set -u
F="python3 $(cd "$(dirname "$0")/.." && pwd)/cli/forge.py"
T=$(mktemp -d); cd "$T"
mkdir -p .opencode/rules
echo '{"dependencies":{"react":"18.3.1"}}' > package.json
echo '{"instructions":["AGENTS.md",".opencode/rules/*.md"]}' > opencode.json
cat > AGENTS.md <<'E'
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
cat > .opencode/rules/coding.md <<'E'
# Coding
Split a file by responsibility. A component reads data through hooks only.
E
ok() { out=$($F rules audit 2>&1) || { echo "FAIL: sound set rejected"; echo "$out"; exit 1; }; }
only() { out=$($F rules audit 2>&1); echo "$out" | grep -q "\[FAIL\] $1" || { echo "FAIL: mutation did not trip '$1'"; echo "$out"; exit 1; }; }
ok
cp -r . ../snap.$$ 2>/dev/null; restore() { rm -rf ./* .opencode; cp -r ../snap.$$/. .; }
rm opencode.json; only wiring; restore
echo '{"instructions":[".opencode/rules/*.md"]}' > opencode.json; only wiring; restore
echo '{"instructions":["AGENTS.md","nope/*.md"]}' > opencode.json; only wiring; restore
echo '| `ghost.md` | nothing |' >> AGENTS.md; only index; restore
echo "extra" > .opencode/rules/orphan.md; only index; restore
echo "TODO write this" >> .opencode/rules/coding.md; only placeholders; restore
echo 'See `coding.md` §Nonexistent section.' >> AGENTS.md; only cross_references; restore
echo 'Coverage 60% is enough.' >> .opencode/rules/coding.md; only thresholds; restore
echo 'Run `forge gate check` first.' >> .opencode/rules/coding.md; only no_forge_coupling; restore
echo 'Use Riverpod for state.' >> .opencode/rules/coding.md; only no_contamination; restore
echo 'Per the profiles, keep it simple.' >> .opencode/rules/coding.md; only no_contamination; restore
echo 'Handle errors properly and, if possible, log them.' >> .opencode/rules/coding.md; only no_unenforceable_prose; restore
sed -i '/vulnerabilities/d' .opencode/rules/quality-gates.md; only gates_are_commands; restore
sed -i 's/`npm audit --audit-level=high`/npm audit/' .opencode/rules/quality-gates.md; only gates_are_commands; restore
python3 -c "print('\n'.join('line %d' % i for i in range(900)))" > .opencode/rules/big.md; echo '| `big.md` | filler |' >> AGENTS.md; only budget; restore
ok
rm -rf ../snap.$$
echo "RULES PASS"
