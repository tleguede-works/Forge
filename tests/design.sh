#!/usr/bin/env bash
# Tests of `forge design check`. Fixtures: a good banking home, then one mutation per rule.
set -u
F="python3 $(cd "$(dirname "$0")/.." && pwd)/cli/forge.py"
T=$(mktemp -d); cd "$T"; $F init --name D >/dev/null
D=.forge/design; mkdir -p $D/screens .forge/plans
ok()   { "$@" >/dev/null 2>&1 || { echo "FAIL (expected pass): $*"; exit 1; }; }
fail() { "$@" >/dev/null 2>&1 && { echo "FAIL (expected refusal): $*"; exit 1; }; true; }
cat > $D/layouts.md <<'L'
# Layouts
## LAY-app Mobile app shell
- region: bottom-nav
- region: content
L
cat > $D/screen-map.md <<'L'
# Screen map
| id | route | layout | role |
|---|---|---|---|
| SCR-001 | /home | LAY-app | user |
L
good() { cat > $D/screens/SCR-001.md <<'S'
# SCR-001 Home
- layout: LAY-app
## Anatomy
| rank | zone | role | why here | attention |
|---|---|---|---|---|
| 1 | Card carousel | context | the cards are what every action applies to | primary |
| 2 | Quick actions | action | actions follow the card they act on | secondary |
| 3 | Recent transactions | detail | scanned after acting, least urgent | tertiary |
S
}
good; ok $F design check
# H1: action above context
sed -i 's/| 1 | Card carousel | context/| 2 | Card carousel | context/; s/| 2 | Quick actions | action/| 1 | Quick actions | action/' $D/screens/SCR-001.md
fail $F design check; good
# two screens in one file
printf '\n# SCR-009 Admin users\n' >> $D/screens/SCR-001.md; fail $F design check; good
# unknown layout
sed -i 's/LAY-app | user/LAY-nope | user/' $D/screen-map.md; fail $F design check; sed -i 's/LAY-nope/LAY-app/' $D/screen-map.md
# missing why
sed -i 's/the cards are what every action applies to/x/' $D/screens/SCR-001.md; fail $F design check; good
# orphan screen file
cp $D/screens/SCR-001.md $D/screens/SCR-002.md; sed -i 's/SCR-001/SCR-002/' $D/screens/SCR-002.md; fail $F design check; rm $D/screens/SCR-002.md
ok $F design check
# layouts must be covered by plans (the forgotten-sidebar case)
echo "Build LAY-app/content" > .forge/plans/p1.md; fail $F design check --plans
echo "Build LAY-app/bottom-nav" >> .forge/plans/p1.md; ok $F design check --plans
echo "DESIGN PASS"
