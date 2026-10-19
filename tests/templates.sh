#!/usr/bin/env bash
# Every skill template contains the sections the CLI requires, so the two sources of truth cannot drift apart.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'P'
import sys,re,pathlib
root=pathlib.Path(sys.argv[1]); sys.path.insert(0,str(root/"cli")); import forge
MAP={"brief":"forge-bootstrap/references/brief-template.md","contract":"forge-bootstrap/references/contract-template.md",
 "landscape":"forge-discover/references/landscape-template.md","prd":"forge-discover/references/prd-template.md",
 "roadmap":"forge-discover/references/roadmap-template.md","compliance-register":"forge-compliance/references/register-template.md",
 "design-references":"forge-design/references/design-references-template.md","design-system":"forge-design/references/design-system-template.md",
 "architecture":"forge-architect/references/architecture-template.md","rules-report":"forge-rules/references/rules-report-template.md",
 "test-plan":"forge-plan/references/test-plan-template.md","validation-report":"forge-build/references/validation-report-template.md"}
bad=0
for name,keys in forge.HEADINGS.items():
    if name not in MAP: print(f"FAIL: no template mapped for {name}"); bad+=1; continue
    t=(root/"skills"/MAP[name]).read_text()
    heads=[forge._norm_heading(m.group(1)) for m in re.finditer(r"^#{1,6}\s+(.*?)\s*$",t,re.M)]
    for k in keys:
        if not any(h.startswith(k) for h in heads): print(f"FAIL: template of {name} lacks section '{k}'"); bad+=1
sys.exit(1 if bad else 0)
P
[ $? -eq 0 ] && echo "TEMPLATES PASS"
