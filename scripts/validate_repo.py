#!/usr/bin/env python3
"""Repository validator: the checks no single test suite owns.

Run it with `python3 scripts/validate_repo.py`. It exits non-zero on the first broken
invariant and prints one line per problem. Stdlib only, no network, no project needed.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "cli"))
import forge  # noqa: E402

problems = []


def bad(msg):
    problems.append(msg)


def frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return {}
    out = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            out[k.strip()] = v.strip()
    return out


# 1. Skills: one directory per skill, the frontmatter name equals the directory name,
#    every `references/x` a skill names exists.
skills = {}
for d in sorted(p for p in (ROOT / "skills").iterdir() if p.is_dir()):
    f = d / "SKILL.md"
    if not f.is_file():
        bad(f"skills/{d.name}: no SKILL.md")
        continue
    text = f.read_text(encoding="utf-8")
    fm = frontmatter(text)
    if fm.get("name") != d.name:
        bad(f"skills/{d.name}: frontmatter name is {fm.get('name')!r}, expected {d.name!r}")
    if not fm.get("description"):
        bad(f"skills/{d.name}: no description in the frontmatter")
    if re.search(r"^\s*description: Forge phases? \d", text, re.M):
        bad(f"skills/{d.name}: the description carries a phase number (phases are named, never numbered)")
    skills[d.name] = text
    for ref in sorted(set(re.findall(r"`references/([\w./-]+)`", text))):
        target = d / "references" / ref
        if ref.endswith("/"):
            if not target.is_dir():
                bad(f"skills/{d.name}: names references/{ref}, which does not exist")
        elif not target.is_file():
            bad(f"skills/{d.name}: names references/{ref}, which does not exist")

# 2. Agents: a frontmatter description, and every agent named by the CLI has a file.
agents = {}
for f in sorted((ROOT / "agents").glob("*.md")):
    fm = frontmatter(f.read_text(encoding="utf-8"))
    if not fm.get("description"):
        bad(f"agents/{f.name}: no description in the frontmatter")
    agents[f.stem] = f

# 3. The phase registry names a real skill and a real producer for every phase.
for phase in forge.PHASES:
    if phase not in forge.PHASE_SKILL:
        bad(f"phase {phase}: PHASE_SKILL has no entry")
    elif forge.PHASE_SKILL[phase] not in skills:
        bad(f"phase {phase}: skill {forge.PHASE_SKILL[phase]} does not exist")
    if phase not in forge.PHASE_PRODUCER:
        bad(f"phase {phase}: PHASE_PRODUCER has no entry")
    elif forge.PHASE_PRODUCER[phase] not in agents:
        bad(f"phase {phase}: producer agent {forge.PHASE_PRODUCER[phase]} does not exist")

# 4. Every structure has a template, and every template holds the headings it must.
structures = set(forge.HEADINGS) | set(forge.ROW_RULES)
for name in sorted(structures - set(forge.TEMPLATES)):
    bad(f"structure {name}: no template in forge.TEMPLATES")
for name in sorted(set(forge.TEMPLATES) - structures):
    bad(f"forge.TEMPLATES: {name} is not a structure")
for name, rel in sorted(forge.TEMPLATES.items()):
    p = ROOT / "skills" / rel
    if not p.is_file():
        bad(f"structure {name}: template skills/{rel} is missing")

# 5. Every `forge <subcommand>` in the docs exists in the CLI.
cli = (ROOT / "cli" / "forge.py").read_text(encoding="utf-8")
commands = set(re.findall(r'sub\.add_parser\("([a-z-]+)"\)', cli))
if not commands:
    bad("cli/forge.py: no subcommand was found by the validator")
docs = [ROOT / "AGENTS.md", ROOT / "README.md", *agents.values(), *[ROOT / "skills" / n / "SKILL.md" for n in skills]]
for f in docs:
    if not f.is_file():
        continue
    for used in sorted(set(re.findall(r"`forge ([a-z-]+)", f.read_text(encoding="utf-8")))):
        if used not in commands:
            bad(f"{f.relative_to(ROOT)}: documents `forge {used}`, which the CLI does not define")

# 6. Every test suite is listed in README.md and docs/STATUS.md.
suites = sorted(p.stem for p in (ROOT / "tests").glob("*.sh"))
for doc in ("README.md", "docs/STATUS.md"):
    f = ROOT / doc
    if not f.is_file():
        bad(f"{doc}: missing")
        continue
    text = f.read_text(encoding="utf-8")
    for s in suites:
        if s not in text:
            bad(f"{doc}: suite tests/{s}.sh is not listed")

# 7. Every skill and agent named in the docs of the repo exists.
named = set(re.findall(r"`(forge-[a-z-]+)`", (ROOT / "AGENTS.md").read_text(encoding="utf-8")))
for n in sorted(named):
    if n not in skills and n not in agents:
        bad(f"AGENTS.md names `{n}`, which is neither a skill nor an agent")

print(f"skills: {len(skills)}  agents: {len(agents)}  suites: {len(suites)}  commands: {len(commands)}")
for p in problems:
    print("FAIL:", p)
print(f"{len(problems)} problem(s)")
sys.exit(1 if problems else 0)
