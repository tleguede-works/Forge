#!/usr/bin/env bash
# The template files and the CLI cannot drift apart: this suite reads forge.TEMPLATES,
# forge.HEADINGS and forge.ROW_RULES instead of keeping a second copy of the mapping.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
import re, subprocess, sys, pathlib
root = pathlib.Path(sys.argv[1]); sys.path.insert(0, str(root / "cli")); import forge

bad = []
def fail(m): bad.append(m)

TOKEN = re.compile(r"<(?!/?(?:br|hr|p|div|span|ul|ol|li|table|tr|td|th|a|b|i|em|strong|code|pre|img|input|button|form|label|h[1-6])\b)[^<>\n]+>")
HEAD = re.compile(r"^(#{1,6})\s+(.*?)\s*$", re.M)

structures = set(forge.HEADINGS) | set(forge.ROW_RULES)
for n in sorted(structures - set(forge.TEMPLATES)):
    fail(f"structure '{n}' has no entry in forge.TEMPLATES")
for n in sorted(set(forge.TEMPLATES) - structures):
    fail(f"forge.TEMPLATES names '{n}', which is not a structure")

for name in sorted(structures & set(forge.TEMPLATES)):
    rel = forge.TEMPLATES[name]
    p = root / "skills" / rel
    if not p.is_file():
        fail(f"{name}: template skills/{rel} does not exist"); continue
    text = p.read_text(encoding="utf-8")
    heads = [m.group(2) for m in HEAD.finditer(text)]
    for key in forge.HEADINGS.get(name, []):
        slug = forge._slug(key)
        hit = [h for h in heads if forge._heading_matches(h, key)]
        if not hit:
            fail(f"{name}: template lacks the section '{key}' the CLI requires")
        elif not any(f"{{#{slug}}}" in h for h in hit):
            fail(f"{name}: section '{key}' carries no {{#{slug}}} anchor (a translated deliverable needs it)")
    if name in forge.ROW_RULES and name != "layouts":
        pat, ncol, shape = forge.ROW_RULES[name]
        if not any(re.match(pat, l) for l in text.splitlines()):
            fail(f"{name}: template has no row matching {shape}")
        elif not any(len(l.strip().strip("|").split("|")) >= ncol for l in text.splitlines() if re.match(pat, l)):
            fail(f"{name}: the example row has fewer than {ncol} columns; write {shape}")
    probs = forge.structure_problems(name, TOKEN.sub("sample text", text))
    if probs:
        fail(f"{name}: the filled template does not satisfy its own structure: {probs}")

# `forge template` prints the skeleton of every structure with its anchors, so a model never
# has to guess a heading. This is the path the other suites use to build their fixtures.
for name in sorted(structures):
    out = subprocess.run([sys.executable, str(root / "cli" / "forge.py"), "template", name],
                         capture_output=True, text=True)
    if out.returncode:
        fail(f"forge template {name} failed: {out.stderr.strip()}"); continue
    for key in forge.HEADINGS.get(name, []):
        if f"{{#{forge._slug(key)}}}" not in out.stdout:
            fail(f"forge template {name} prints no heading for '{key}'")

# The metadata a structure needs above its first section (register markets, rules-report target)
# must be in the template file and in the skeleton, or a model that copies the skeleton writes a
# deliverable its own gate refuses.
for name, lines in sorted(forge.PREAMBLE.items()):
    rel = forge.TEMPLATES.get(name, "")
    text = (root / "skills" / rel).read_text(encoding="utf-8") if rel else ""
    out = subprocess.run([sys.executable, str(root / "cli" / "forge.py"), "template", name],
                         capture_output=True, text=True).stdout
    for line in lines:
        head = line.split(":", 1)[0]
        if not any(l.startswith(head + ":") for l in text.splitlines()):
            fail(f"{name}: the template file has no '{head}:' header")
        if not any(l.startswith(head + ":") for l in out.splitlines()):
            fail(f"forge template {name} prints no '{head}:' header")

print("\n".join(f"FAIL: {m}" for m in bad))
sys.exit(1 if bad else 0)
PY
[ $? -eq 0 ] && echo "TEMPLATES PASS"
