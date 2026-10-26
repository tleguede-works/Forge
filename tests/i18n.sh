#!/usr/bin/env bash
# A project whose language is not English: translated headings with anchors pass every structure check.
set -u
CLIDIR="$(cd "$(dirname "$0")/.." && pwd)/cli"; export CLIDIR
F="python3 $CLIDIR/forge.py"
T=$(mktemp -d); cd "$T"
ok()   { "$@" >/dev/null 2>&1 || { echo "FAIL (expected success): $*"; exit 1; }; }
fail() { "$@" >/dev/null 2>&1 && { echo "FAIL (expected refusal): $*"; exit 1; }; true; }
ok $F init --name FR --lang fr; ok $F phase start bootstrap
$F template contract | grep -q "{#parties-and-roles}" || { echo "FAIL: forge template prints no anchors"; exit 1; }
cat > .forge/contract.md <<'E'
# Contrat
## 1. Parties et rôles {#parties-and-roles}
Texte de remplissage.
## 2. Déroulement du travail {#how-the-work-runs}
Texte de remplissage.
## 3. Points de passage et délais {#touchpoints-and-answer-times}
Texte de remplissage.
## 4. Changements après approbation {#changes-after-approval}
Texte de remplissage.
## 5. Hors contrat {#not-included}
Texte de remplissage.
## 6. Langue des livrables {#language-of-deliverables}
Français.
E
ok $F register contract .forge/contract.md
sed -i 's/ {#not-included}//' .forge/contract.md
fail $F register contract .forge/contract.md                      # a translated heading without its anchor is not recognised
# PRD: the out-of-scope section is found by its anchor
python3 - <<'P'
import os,sys; sys.path.insert(0,os.environ["CLIDIR"]); import forge,pathlib
R=forge.find_root()
(R/".forge"/"prd.md").write_text("## 3. Règles métier {#business-rules}\n- B1 le paiement est capturé par carte (source: user-stated)\n## 10. Hors périmètre {#out-of-scope}\n- B2 paiement par virement : retiré, hors du MVP\n")
live,gone=forge.parse_prd(R); assert live=={"B1"} and gone=={"B2"},(live,gone)
assert forge.prd_problems(R)==[],forge.prd_problems(R)
P
# screens: Anatomie with the anchor
mkdir -p .forge/design/screens
printf '| id | route | layout | role | release |\n|---|---|---|---|---|\n| SCR-001 | /accueil | LAY-app | user | MVP |\n' > .forge/design/screen-map.md
printf '## MVP\nx\n' > .forge/roadmap.md; printf '## LAY-app Coque\n- region: contenu\n' > .forge/design/layouts.md
cat > .forge/design/screens/SCR-001.md <<'E'
# SCR-001 Accueil
- layout: LAY-app
## Anatomie {#anatomy}
| rank | zone | role | why here | attention |
|---|---|---|---|---|
| 1 | Carrousel de comptes | context | le compte est l'objet de toute action | primary |
| 2 | Actions rapides | action | agir sur le compte choisi | secondary |
E
ok $F design check
sed -i 's/ {#anatomy}//' .forge/design/screens/SCR-001.md
fail $F design check                                              # "Anatomie" alone is not recognised
echo "I18N PASS"
