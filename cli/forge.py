#!/usr/bin/env python3
"""forge - single entry point for every Forge state change. Python 3.9+, stdlib only."""
import argparse, hashlib, json, re, sys
from datetime import datetime, timezone
from pathlib import Path

VERSION = 3
PHASES = ["bootstrap", "landscape", "prd", "roadmap", "design",
          "architecture", "rules", "plans", "build", "validation"]
REQUIRED = {
    "bootstrap": ["contract", "brief"],
    "landscape": ["landscape"],
    "prd": ["prd"],
    "roadmap": ["roadmap"],
    "design": ["design-references", "screen-map", "layouts", "design-system"],
    "architecture": ["architecture", "slices"],
    "rules": ["rules-report"],
    "plans": ["plans-index", "test-plan"],
    "build": [],
    "validation": ["validation-report"],
}
PREFIX_PHASE = {"screen:": "design", "plan:": "plans"}  # multi-instance deliverables
REVIEWERS = ("qa", "redteam")
TOUCHPOINTS = ("bootstrap", "prd", "design", "validation")  # client-mode phases that need the client
BLOCKING = ("critical", "major")
BEGIN, END = "<!-- forge:start v3 -->", "<!-- forge:end -->"
BANNED = [r"\bif possible\b", r"\bideally\b", r"\bpreferably\b", r"\bgenerally\b", r"\bnormally\b",
          r"\bat a minimum\b", r"\bat least\b", r"\bshould\b", r"\bmay\b", r"\bmight\b",
          r"\btry to\b", r"\bconsider\b", r"\bas appropriate\b", r"\bwhen appropriate\b",
          r"\bfeel free\b", r"\busually\b", r"\bwhere possible\b", r"\bwhenever possible\b", r"\bwherever possible\b", r"\bas needed\b",
          r"\bunless otherwise\b", r"\bdepending on the case\b"]


def die(msg, code=1):
    print(f"forge: {msg}", file=sys.stderr)
    sys.exit(code)


def now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def find_root(start=None):
    p = Path(start or Path.cwd()).resolve()
    for d in [p, *p.parents]:
        if (d / ".forge" / "state.json").is_file():
            return d
    return None


def need_root():
    r = find_root()
    if not r:
        die("no .forge/state.json found from the current directory; run `forge init`")
    return r


def seal_of(s):
    body = {k: v for k, v in s.items() if k != "seal"}
    return hashlib.sha256(json.dumps(body, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()[:24]


def load(root):
    s = json.loads((root / ".forge" / "state.json").read_text(encoding="utf-8"))
    if s.get("v") != VERSION:
        die(f"state version {s.get('v')} is not {VERSION}")
    if s.pop("seal", None) != seal_of(s):
        die("state.json was edited outside the forge CLI (rule R2). Restore it from version control; "
            "do not continue until `forge status` works")
    return s


def save(root, s):
    s["seal"] = seal_of(s)
    (root / ".forge" / "state.json").write_text(
        json.dumps(s, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    s.pop("seal")


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()[:16]


def phase_of(name):
    for pre, ph in PREFIX_PHASE.items():
        if name.startswith(pre):
            return ph
    for ph, names in REQUIRED.items():
        if name in names:
            return ph
    return None


def mem(root, name):
    return root / ".forge" / "memory" / name


def journal(root, event, text):
    with mem(root, "journal.md").open("a", encoding="utf-8") as f:
        f.write(f"- {now()} | {event} | {text}\n")


# ---------------------------------------------------------------- init
def cmd_init(a):
    root = Path(a.path).resolve()
    if (root / ".forge" / "state.json").exists():
        die("already initialised")
    (root / ".forge" / "memory").mkdir(parents=True)
    s = {"v": VERSION, "project": a.name, "lang": a.lang, "mode": "interactive",
         "phase": {"current": None},
         "phases": {p: "pending" for p in PHASES}, "deliverables": {}}
    save(root, s)
    for n, h in (("journal.md", "# Journal (append-only)\n\n"),
                 ("decisions.md", "# Decisions\n\n"),
                 ("lessons.md", "# Lessons\n\n")):
        mem(root, n).write_text(h, encoding="utf-8")
    write_now(root, "Project initialised", "Run `forge phase start bootstrap`", [], "")
    inject_agents_md(root)
    journal(root, "init", f"project={a.name} lang={a.lang}")
    print(f"initialised {root}/.forge")


def inject_agents_md(root):
    block = f"""{BEGIN}
## Forge
This project is driven by Forge. Run `forge status` before any work.
- State changes go through the `forge` CLI only. Never edit `.forge/state.json` by hand.
- On session start and after any context compaction, run `forge memory resume` and read its output.
- Deliverables live in `.forge/`, written in the project language (see `forge status`).
- Orchestrator agent: `forge`. Skills: `forge`, `forge-memory`.
{END}
"""
    f = root / "AGENTS.md"
    txt = f.read_text(encoding="utf-8") if f.exists() else ""
    pat = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n?", re.S)
    txt = pat.sub(block, txt) if pat.search(txt) else (txt.rstrip() + "\n\n" if txt else "") + block
    f.write_text(txt, encoding="utf-8")


# ---------------------------------------------------------------- status / mode / phase
def drift(r, s):
    out = []
    for n, d in s["deliverables"].items():
        if s["phases"][d["phase"]] == "approved":
            p = r / d["path"]
            if not p.is_file():
                out.append((n, f"{n}: approved deliverable is missing", d["phase"]))
            elif sha(p) != d["hash"]:
                out.append((n, f"{n}: changed after its phase was approved", d["phase"]))
    if s.get("rules") and s["phases"]["rules"] == "approved" and rules_hash(r) != s["rules"]["hash"]:
        out.append(("rules", "rule files changed after the rules phase was approved", "rules"))
    return out


def cmd_status(a):
    r = need_root(); s = load(r)
    kp = kit_problems()
    if kp:
        print("KIT MODIFIED: " + "; ".join(kp[:5]) + ". Reinstall Forge before approving anything")
    for _, msg, ph in drift(r, s):
        print(f"DRIFT: {msg}. Run `forge phase reopen {ph} --reason ...` or restore the file")
    cur = s["phase"]["current"]
    print(f"project={s['project']} lang={s['lang']} mode={s['mode']} phase={cur}")
    for p in PHASES:
        print(f"  {p:<13}{s['phases'][p]}")
    n = len(s.get("client", {}).get("pending", []))
    if n:
        print(f"client points pending: {n} (forge client list)")
    print("next:", next_action(s, r))


def next_action(s, r=None):
    cur = s["phase"]["current"]
    if cur is None:
        return "forge phase start bootstrap"
    if s["phases"][cur] == "approved":
        i = PHASES.index(cur)
        return f"forge phase start {PHASES[i+1]}" if i + 1 < len(PHASES) else "done"
    missing = [n for n in REQUIRED[cur] if n not in s["deliverables"]]
    if cur == "plans" and r is not None:
        missing += [f"plan:{x[0]}" for x in parse_slices(r) if f"plan:{x[0]}" not in s["deliverables"]]
    if missing:
        return f"produce and register: {', '.join(missing)}"
    if cur == "build" and r is not None:
        todo = [x[0] for x in parse_slices(r) if s.get("slices", {}).get(x[0]) != "done"]
        run = [k for k, v in s.get("slices", {}).items() if v == "in_progress"]
        if run:
            return f"finish slice {run[0]}, then forge slice done {run[0]} --evidence \"<command> : <result>\""
        return f"forge slice start {todo[0]}" if todo else "forge gate check"
    return "forge gate check"


def cmd_mode(a):
    r = need_root(); s = load(r)
    if len((a.evidence or "").strip()) < 3:
        die("changing the mode needs --evidence with the user's own words asking for it")
    s["mode"] = a.value; save(r, s)
    journal(r, "mode", f"{a.value} evidence={a.evidence!r}"); print("mode =", a.value)


def cmd_phase_start(a):
    r = need_root(); s = load(r)
    i = PHASES.index(a.phase)
    if i > 0 and s["phases"][PHASES[i-1]] != "approved":
        die(f"phase_order: {PHASES[i-1]} is not approved")
    if s["phases"][a.phase] != "pending":
        die(f"phase {a.phase} is already {s['phases'][a.phase]}")
    dr = drift(r, s)
    if dr:
        die("approved work drifted: " + "; ".join(m for _, m, _ in dr) + ". Reopen the phase or restore the files")
    s["phases"][a.phase] = "in_progress"; s["phase"]["current"] = a.phase
    save(r, s); journal(r, "phase_start", a.phase)
    write_now(r, f"Phase {a.phase} started", next_action(s, r), [], "")
    print("started", a.phase)


# ---------------------------------------------------------------- deliverables & reviews
def cmd_register(a):
    r = need_root(); s = load(r)
    ph = phase_of(a.name)
    if ph is None or not re.fullmatch(r"[a-z][a-z-]*|screen:SCR-\d+|plan:S\d+", a.name):
        die(f"unknown deliverable name '{a.name}' (allowed: the names in REQUIRED, screen:SCR-<n>, plan:S<n>)")
    if ph != s["phase"]["current"] or s["phases"][ph] != "in_progress":
        die(f"premature_artifact: '{a.name}' belongs to phase {ph}, current is {s['phase']['current']}")
    p = (r / a.path).resolve()
    if not p.is_file() or r / ".forge" not in p.parents:
        die("deliverable must be an existing file inside .forge/")
    txt = p.read_text(encoding="utf-8")
    if re.search(r"\{\{[A-Z_]+\}\}|\bTODO\b|\bTBD\b", txt):
        die("placeholders found (a {{TOKEN}}, TODO or TBD remains)")
    h = sha(p)
    old = s["deliverables"].get(a.name)
    entry = {"path": str(p.relative_to(r)), "phase": ph, "hash": h,
             "requires": sorted(set(a.requires.split(","))) if a.requires else [],
             "reviews": {}}
    if old and old["hash"] == h:
        entry["reviews"] = old["reviews"]
    s["deliverables"][a.name] = entry
    save(r, s); journal(r, "register", f"{a.name} {h}")
    print(f"registered {a.name} hash={h}" + (" (reviews reset)" if old and old["hash"] != h else ""))


def cmd_review(a):
    r = need_root(); s = load(r)
    d = s["deliverables"].get(a.name) or die(f"'{a.name}' is not registered")
    if sha(r / d["path"]) != d["hash"]:
        die("stale: the file changed since registration; run `forge register` again")
    exp = r / ".forge" / "reviews" / (a.name.replace(":", "_") + "." + a.agent + ".json")
    if Path(a.report).resolve() != exp.resolve() or not exp.is_file():
        die(f"the report must be the file {exp.relative_to(r)} written by the reviewing agent")
    rep = json.loads(exp.read_text(encoding="utf-8"))
    findings = rep.get("findings")
    if not isinstance(findings, list):
        die("report needs a 'findings' list")
    blocking = 0
    for f in findings:
        for k in ("id", "severity", "status", "evidence"):
            if k not in f:
                die(f"finding missing '{k}': {f}")
        if f["severity"] not in ("critical", "major", "minor"):
            die(f"bad severity in {f['id']}")
        if f["status"] not in ("open", "resolved", "dismissed"):
            die(f"bad status in {f['id']}")
        if f["status"] == "dismissed":
            m = re.search(r"\bD-\d+\b", f.get("reason", ""))
            dec = mem(r, "decisions.md").read_text(encoding="utf-8")
            if not m or f"## {m.group(0)} " not in dec:
                die(f"{f['id']}: a dismissed finding must cite a recorded decision (reason 'D-<n>' created with forge memory decide)")
            blk = dec.split(f"## {m.group(0)} ", 1)[1].split("\n## ", 1)[0]
            if f["severity"] in BLOCKING and not re.search(r"^user-evidence:\s*\S{3,}", blk, re.M):
                die(f"{f['id']}: dismissing a {f['severity']} finding needs a decision recorded with --user-evidence (the user's own words)")
        if f["status"] == "open" and f["severity"] in BLOCKING:
            blocking += 1
    verdict = "ok" if blocking == 0 else "blocked"
    d["reviews"][a.agent] = {"hash": d["hash"], "verdict": verdict, "findings": len(findings),
                             "blocking": blocking, "report": str(exp.relative_to(r)), "report_hash": sha(exp)}
    save(r, s); journal(r, "review", f"{a.name} {a.agent} {verdict} blocking={blocking}")
    print(f"{a.agent} review of {a.name}: {verdict} (blocking={blocking})")
    sys.exit(0 if verdict == "ok" else 1)


# ---------------------------------------------------------------- gate
def gate_problems(r, s, ph):
    out = []
    for n in REQUIRED[ph]:
        if n not in s["deliverables"]:
            out.append(f"missing deliverable: {n}")
    if PHASES.index(ph) >= PHASES.index("roadmap"):
        out += premises_problems(r, s)
    if ph == "prd":
        out += prd_problems(r)
    if ph == "roadmap":
        out += roadmap_problems(r)
    if ph == "architecture":
        out += coverage_problems(r)
    if ph == "rules":
        out += rules_gate_problems(r, s)
    if ph == "plans":
        out += plans_problems(r, s)
    if ph == "build":
        rows = parse_slices(r)
        if not rows:
            out.append("slices.md has no S<n> rows")
        out += [f"slice {x[0]} is {s.get('slices', {}).get(x[0], 'pending')}, not done" for x in rows
                if s.get("slices", {}).get(x[0]) != "done"]
    if ph == "design":
        out += design_problems(r)
        for row in parse_screen_map(r):
            if f"screen:{row[0]}" not in s["deliverables"]:
                out.append(f"screen {row[0]} is not registered (forge register screen:{row[0]} ...)")
    if ph == "plans":
        out += layout_plan_problems(r)
    for n, d in s["deliverables"].items():
        if d["phase"] != ph:
            continue
        if not (r / d["path"]).is_file():
            out.append(f"{n}: file missing"); continue
        if sha(r / d["path"]) != d["hash"]:
            out.append(f"{n}: stale (file changed after registration)"); continue
        for ag in REVIEWERS:
            rv = d["reviews"].get(ag)
            if not rv:
                out.append(f"{n}: no {ag} review")
            elif rv["hash"] != d["hash"]:
                out.append(f"{n}: {ag} review is for an older version")
            elif not (r / rv["report"]).is_file() or sha(r / rv["report"]) != rv["report_hash"]:
                out.append(f"{n}: {ag} report file is missing or was changed after it was recorded")
            elif rv["verdict"] != "ok":
                out.append(f"{n}: {ag} review has {rv['blocking']} blocking finding(s)")
    return out


def cmd_gate(a):
    r = need_root(); s = load(r)
    ph = s["phase"]["current"] or die("no active phase")
    if s["phases"][ph] != "in_progress":
        die(f"phase {ph} is {s['phases'][ph]}")
    probs = gate_problems(r, s, ph)
    if probs:
        print(f"GATE {ph}: BLOCKED"); [print("  -", p) for p in probs]; sys.exit(1)
    if a.action == "check":
        print(f"GATE {ph}: all mechanical checks pass; user approval still required"); return
    if not a.evidence or len(a.evidence.strip()) < 2:
        die("approve needs --evidence with the user's own approval words")
    kp = kit_problems()
    if kp:
        die("the installed Forge kit was modified (" + "; ".join(kp[:3]) + "); reinstall before approving")
    if s["mode"] == "client" and ph in TOUCHPOINTS:
        rv = s.get("client", {}).get("reviews", {}).get(ph)
        rep_ = r / ".forge" / "reviews" / f"{ph}.client.json"
        if not rv:
            die(f"client mode, touchpoint {ph}: write .forge/client/{ph}-summary.md, run the forge-client-liaison agent on it, "
                f"resolve its questions, then `forge client review --phase {ph} --document ... --report ...`")
        if not (r / rv["document"]).is_file() or sha(r / rv["document"]) != rv["doc_hash"]:
            die("the client summary changed after the liaison review; run the review again")
        if not rep_.is_file() or sha(rep_) != rv["report_hash"]:
            die("the liaison report changed after it was recorded")
        if rv["unresolved"]:
            die(f"{rv['unresolved']} liaison question(s) have no resolution")
    if a.evidence.strip().lower() == "auto":
        if s["mode"] != "client" or ph in TOUCHPOINTS:
            die(f"auto approval is allowed only in client mode, outside the touchpoint phases {TOUCHPOINTS}")
    s["phases"][ph] = "approved"
    if ph == "rules":
        t_, b_ = rules_cfg(r, s)
        s["rules"] = {"hash": rules_hash(r), "target": t_, "budget": b_}
    save(r, s)
    journal(r, "gate_approved", f"{ph} evidence={a.evidence!r}")
    write_now(r, f"Phase {ph} approved", next_action(s, r), [], "")
    print(f"phase {ph} approved")


# ---------------------------------------------------------------- memory
def write_now(root, task, nxt, files, blockers):
    (root / ".forge" / "memory" / ".edits").unlink(missing_ok=True)
    mem(root, "NOW.md").write_text(
        f"# NOW (overwritten at every checkpoint)\n\n- updated: {now()}\n"
        f"- task: {task}\n- next action: {nxt}\n"
        f"- files touched: {', '.join(files) if files else 'none'}\n"
        f"- blockers: {blockers or 'none'}\n", encoding="utf-8")


def cmd_memory(a):
    r = need_root()
    if a.action == "resume":
        print(mem(r, "NOW.md").read_text(encoding="utf-8"))
        print("--- last journal lines ---")
        print("".join(mem(r, "journal.md").read_text(encoding="utf-8").splitlines(True)[-8:]))
    elif a.action == "checkpoint":
        files = [f for f in (a.files or "").split(",") if f]
        write_now(r, a.task, a.next, files, a.blockers or "")
        journal(r, "checkpoint", a.task); print("checkpoint written")
    elif a.action in ("decide", "learn"):
        fn = "decisions.md" if a.action == "decide" else "lessons.md"
        pre = "D" if a.action == "decide" else "L"
        p = mem(r, fn)
        n = len(re.findall(rf"^## {pre}-\d+", p.read_text(encoding="utf-8"), re.M)) + 1
        with p.open("a", encoding="utf-8") as f:
            f.write(f"## {pre}-{n:03d} ({now()})\n{a.text}\n" + (f"user-evidence: {a.user_evidence}\n" if a.user_evidence else "") + "\n")
        journal(r, a.action, f"{pre}-{n:03d}"); print(f"{pre}-{n:03d} recorded")
    elif a.action == "log":
        journal(r, "note", a.text); print("logged")


# ---------------------------------------------------------------- design checks
ROLES = {"context", "summary", "action", "detail", "navigation", "feedback"}
ATTENTION = {"primary", "secondary", "tertiary"}


def md_rows(text, heading):
    """Rows (list of cell lists, header excluded) of the first table under '## heading'."""
    m = re.search(rf"^## {re.escape(heading)}\s*$(.*?)(?=^## |\Z)", text, re.S | re.M)
    if not m:
        return None
    rows = []
    for line in m.group(1).splitlines():
        line = line.strip()
        if line.startswith("|") and not re.match(r"^\|[\s:|-]+\|?$", line):
            rows.append([c.strip() for c in line.strip("|").split("|")])
    return rows[1:] if rows else []


def parse_layouts(root):
    f = root / ".forge" / "design" / "layouts.md"
    out = {}
    if f.is_file():
        cur = None
        for line in f.read_text(encoding="utf-8").splitlines():
            m = re.match(r"^## (LAY-[\w-]+)", line)
            if m:
                cur = m.group(1); out[cur] = []
            m = re.match(r"^- region:\s*(\S+)", line)
            if m and cur:
                out[cur].append(m.group(1))
    return out


def parse_screen_map(root):
    f = root / ".forge" / "design" / "screen-map.md"
    rows = []
    if f.is_file():
        for line in f.read_text(encoding="utf-8").splitlines():
            if re.match(r"^\|\s*SCR-", line):
                c = [x.strip() for x in line.strip().strip("|").split("|")]
                if len(c) >= 4:
                    rows.append(c)
    return rows


def design_problems(root):
    out = []
    d = root / ".forge" / "design"
    layouts = parse_layouts(root)
    rows = parse_screen_map(root)
    if not rows:
        out.append("screen-map.md has no SCR- rows")
    if not layouts:
        out.append("layouts.md defines no LAY- layout")
    ids = [r[0] for r in rows]
    for dup in {i for i in ids if ids.count(i) > 1}:
        out.append(f"screen-map: duplicate id {dup}")
    for sid, route, lay, role in [r[:4] for r in rows]:
        if lay not in layouts:
            out.append(f"{sid}: layout '{lay}' is not defined in layouts.md")
        f = d / "screens" / f"{sid}.md"
        if not f.is_file():
            out.append(f"{sid}: file screens/{sid}.md is missing"); continue
        txt = f.read_text(encoding="utf-8")
        h1 = re.findall(r"^# (.+)$", txt, re.M)
        if len(h1) != 1:
            out.append(f"{sid}: {len(h1)} level-1 headings (one screen per file, exactly one H1)")
        elif not h1[0].startswith(sid):
            out.append(f"{sid}: H1 must start with the screen id")
        m = re.search(r"^- layout:\s*(\S+)", txt, re.M)
        if not m or m.group(1) != lay:
            out.append(f"{sid}: file layout '{m.group(1) if m else None}' differs from screen-map '{lay}'")
        zones = md_rows(txt, "Anatomy")
        if not zones:
            out.append(f"{sid}: Anatomy table missing or empty"); continue
        ranks, roles, prim = [], {}, 0
        for z in zones:
            if len(z) < 5:
                out.append(f"{sid}: anatomy row needs 5 columns (rank|zone|role|why here|attention)"); continue
            rk, zone, rl, why, att = z[:5]
            if not rk.isdigit():
                out.append(f"{sid}: rank '{rk}' is not a number"); continue
            ranks.append(int(rk))
            if rl not in ROLES:
                out.append(f"{sid}: zone '{zone}' has role '{rl}' (allowed: {sorted(ROLES)})")
            if len(why) < 8:
                out.append(f"{sid}: zone '{zone}' lacks a 'why here' justification")
            if att not in ATTENTION:
                out.append(f"{sid}: zone '{zone}' attention must be one of {sorted(ATTENTION)}")
            prim += att == "primary"
            roles.setdefault(rl, []).append(int(rk))
        if ranks != list(range(1, len(ranks) + 1)):
            out.append(f"{sid}: ranks must be 1..n in order, got {ranks}")
        if prim != 1:
            out.append(f"{sid}: exactly one zone must have attention=primary (found {prim})")
        low = lambda k: min(roles[k]) if k in roles else None
        ctx = [v for v in (low("context"), low("summary")) if v]
        if ctx and low("action") and min(ctx) > low("action"):
            out.append(f"{sid}: H1 violated: an action zone ranks above the context/summary it acts on")
        if low("summary") and low("detail") and low("summary") > low("detail"):
            out.append(f"{sid}: H2 violated: a detail zone ranks above the summary")
        reg = layouts.get(lay, [])
        for r_ in re.findall(r"^- region-used:\s*(\S+)", txt, re.M):
            if r_ not in reg:
                out.append(f"{sid}: uses region '{r_}' that layout {lay} does not define")
    for f in sorted((d / "screens").glob("*.md")) if (d / "screens").is_dir() else []:
        if f.stem not in ids:
            out.append(f"screens/{f.name}: not listed in screen-map.md")
    return out


def layout_plan_problems(root):
    out = []
    plans = "\n".join(p.read_text(encoding="utf-8") for p in sorted((root / ".forge" / "plans").glob("*.md"))) \
        if (root / ".forge" / "plans").is_dir() else ""
    for lay, regions in parse_layouts(root).items():
        for rg in regions:
            if f"{lay}/{rg}" not in plans:
                out.append(f"layout region {lay}/{rg} has no task in .forge/plans/ (write the token '{lay}/{rg}' in the plan task that builds it)")
    return out


def cmd_design(a):
    r = need_root()
    probs = layout_plan_problems(r) if a.plans else design_problems(r)
    if probs:
        print("DESIGN CHECK: FAILED"); [print("  -", p) for p in probs]; sys.exit(1)
    print("DESIGN CHECK: pass" + (" (layouts covered by plans)" if a.plans else ""))


# ---------------------------------------------------------------- coverage, plans, premises
ID_RE = r"[BEVC]\d+"


def parse_prd(root):
    f = root / ".forge" / "prd.md"
    if not f.is_file():
        return None
    txt = f.read_text(encoding="utf-8")
    m = re.search(r"^## 9\.", txt, re.M)
    head, tail = (txt[:m.start()], txt[m.start():]) if m else (txt, "")
    pat = rf"^- \**({ID_RE})\b"
    return set(re.findall(pat, head, re.M)), set(re.findall(pat, tail, re.M))


def prd_problems(root):
    f = root / ".forge" / "prd.md"
    if not f.is_file():
        return ["prd.md is missing"]
    txt = f.read_text(encoding="utf-8")
    m = re.search(r"^## 9\.", txt, re.M)
    head, tail = (txt[:m.start()], txt[m.start():]) if m else (txt, "")
    pat = rf"^- \**({ID_RE})\b"
    live, gone = re.findall(pat, head, re.M), set(re.findall(pat, tail, re.M))
    out = [f"{i} is defined {live.count(i)} times (an ID is unique)" for i in sorted(set(live)) if live.count(i) > 1]
    out += [f"{i} is both live and withdrawn (an ID is never reused)" for i in sorted(set(live) & gone)]
    if not live:
        out.append("the PRD defines no requirement ID (B, E, V or C)")
    return out


def roadmap_problems(root):
    prd, f = parse_prd(root), root / ".forge" / "roadmap.md"
    if prd is None or not f.is_file():
        return ["prd.md or roadmap.md is missing"]
    live, gone = prd
    txt = f.read_text(encoding="utf-8")
    seen = set(re.findall(rf"\b({ID_RE})\b", txt))
    out = [f"requirement {i} appears in no release and not in out of scope" for i in sorted(live - seen)]
    out += [f"roadmap cites {i}, which does not exist in the PRD" for i in sorted(seen - live - gone)]
    return out


def parse_slices(root):
    f = root / ".forge" / "slices.md"
    rows = []
    if f.is_file():
        for line in f.read_text(encoding="utf-8").splitlines():
            if re.match(r"^\|\s*S\d+\s*\|", line):
                c = [x.strip() for x in line.strip().strip("|").split("|")]
                if len(c) >= 4:
                    rows.append((c[0], c[1], c[2], {x.strip() for x in c[3].split(",") if x.strip() not in ("", "-")}))
    return rows


def coverage_problems(root):
    prd, rows, out = parse_prd(root), parse_slices(root), []
    if prd is None:
        return ["prd.md is missing"]
    live, gone = prd
    if not rows:
        return ["slices.md has no S<n> rows"]
    served = set()
    for sid, name, mod, serves in rows:
        for i in sorted(serves):
            if i in gone:
                out.append(f"{sid} serves {i}, which is out of scope (PRD section 9)")
            elif i not in live:
                out.append(f"{sid} serves {i}, which does not exist in the PRD")
        served |= serves
    for i in sorted(live - served, key=lambda x: (x[0], int(x[1:]))):
        out.append(f"requirement {i} is served by no slice")
    return out


def premises_problems(root, s):
    prd = parse_prd(root)
    if prd is None:
        return []
    live, gone = prd
    out = []
    for n, d in s["deliverables"].items():
        for i in d.get("requires", []):
            if i in gone:
                out.append(f"{n} depends on {i}, which was withdrawn (PRD section 9)")
            elif i not in live:
                out.append(f"{n} depends on {i}, which does not exist in the PRD")
    return out


def plans_problems(root, s):
    out, prd, rows = [], parse_prd(root), parse_slices(root)
    if not rows:
        return ["slices.md has no S<n> rows"]
    for sid, name, mod, serves in rows:
        d = s["deliverables"].get(f"plan:{sid}")
        if not d:
            out.append(f"{sid}: no registered plan (forge register plan:{sid} .forge/plans/{sid}.md)"); continue
        txt = (root / d["path"]).read_text(encoding="utf-8")
        for h in ("## Serves", "## Tasks", "## Acceptance", "## Test cases"):
            if h not in txt:
                out.append(f"{sid}: plan lacks section '{h}'")
        n = len(re.findall(r"^- \[[ x]\] T\d+", txt, re.M))
        if not 1 <= n <= 15:
            out.append(f"{sid}: plan has {n} tasks (allowed 1 to 15; split the slice above 15)")
        m = re.search(r"^- serves:\s*(.+)$", txt, re.M)
        declared = {x.strip() for x in m.group(1).split(",")} if m else set()
        if declared != serves:
            out.append(f"{sid}: plan 'serves' {sorted(declared)} differs from slices.md {sorted(serves)}")
        if not re.findall(rf"^- TC-{sid}-\d+", txt, re.M):
            out.append(f"{sid}: plan has no test case (line starting '- TC-{sid}-<n>')")
    ix, tp = s["deliverables"].get("plans-index"), s["deliverables"].get("test-plan")
    if ix:
        itxt = (root / ix["path"]).read_text(encoding="utf-8")
        out += [f"plans-index does not list {sid}" for sid, *_ in rows if not re.search(rf"\b{sid}\b", itxt)]
    if tp:
        ttxt = (root / tp["path"]).read_text(encoding="utf-8")
        out += [f"test-plan does not mention slice {sid}" for sid, *_ in rows if not re.search(rf"\b{sid}\b", ttxt)]
        if prd:
            for i in sorted(prd[0]):
                if i[0] in "BEV" and not re.search(rf"\b{i}\b", ttxt):
                    out.append(f"test-plan covers no test for {i}")
    return out


def cmd_check(a):
    r = need_root(); s = load(r)
    probs = {"coverage": lambda: coverage_problems(r), "premises": lambda: premises_problems(r, s),
             "plans": lambda: plans_problems(r, s)}[a.what]()
    if probs:
        print(f"CHECK {a.what}: FAILED"); [print("  -", p) for p in probs]; sys.exit(1)
    print(f"CHECK {a.what}: pass")


# ---------------------------------------------------------------- slices, reopen, client
def cmd_slice(a):
    r = need_root(); s = load(r)
    if s["phase"]["current"] != "build" or s["phases"]["build"] != "in_progress":
        die("slice commands run only while the build phase is in progress")
    ids = [x[0] for x in parse_slices(r)]
    if a.id not in ids:
        die(f"unknown slice {a.id}")
    sl = s.setdefault("slices", {})
    st = sl.get(a.id, "pending")
    if a.action == "start":
        if st != "pending":
            die(f"{a.id} is {st}")
        busy = [k for k, v in sl.items() if v == "in_progress"]
        if busy:
            die(f"one slice at a time: {busy[0]} is in progress")
        if f"plan:{a.id}" not in s["deliverables"]:
            die(f"{a.id} has no registered plan")
        sl[a.id] = "in_progress"
        save(r, s); journal(r, "slice_start", a.id)
        write_now(r, f"Implementing {a.id}", f"follow .forge/plans/{a.id}.md, tests first", [], "")
    else:
        if st != "in_progress":
            die(f"{a.id} is {st}")
        if not re.match(r"^.{3,}\s:\s.{3,}$", (a.evidence or "").strip()):
            die("done needs --evidence shaped '<test command> : <result>'")
        sl[a.id] = "done"
        save(r, s); journal(r, "slice_done", f"{a.id} evidence={a.evidence!r}")
        write_now(r, f"{a.id} done", "start the next slice or run forge gate check", [], "")
    print(f"{a.id}: {sl[a.id]}")


def cmd_reopen(a):
    r = need_root(); s = load(r)
    if s["phases"][a.phase] != "approved":
        die(f"only an approved phase can be reopened ({a.phase} is {s['phases'][a.phase]})")
    if len(a.reason.strip()) < 8:
        die("--reason is required (what changed and why)")
    i = PHASES.index(a.phase)
    for p in PHASES[i + 1:]:
        s["phases"][p] = "pending"
    for d in s["deliverables"].values():
        if PHASES.index(d["phase"]) > i:
            d["reviews"] = {}
    s["phases"][a.phase] = "in_progress"; s["phase"]["current"] = a.phase
    save(r, s)
    with mem(r, "decisions.md").open("a", encoding="utf-8") as f:
        f.write(f"## REOPEN {a.phase} ({now()})\n{a.reason}\n\n")
    journal(r, "reopen", f"{a.phase}: {a.reason}")
    write_now(r, f"Phase {a.phase} reopened", "edit, re-register, re-review, then gate; later phases restart", [], "")
    print(f"reopened {a.phase}; later phases are pending and their reviews are reset")


def cmd_client(a):
    r = need_root(); s = load(r)
    cl = s.setdefault("client", {"pending": [], "decided": []})
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    if a.action == "ask":
        for k in ("what", "price", "by", "if_no_answer"):
            if not getattr(a, k):
                die(f"--{k.replace('_', '-')} is required")
        try:
            datetime.strptime(a.by, "%Y-%m-%d")
        except ValueError:
            die("--by must be YYYY-MM-DD")
        n = len(cl["pending"]) + len(cl["decided"]) + 1
        cl["pending"].append({"id": n, "kind": a.kind, "what": a.what, "price": a.price,
                              "by": a.by, "if_no_answer": a.if_no_answer})
        save(r, s); journal(r, "client_ask", f"#{n} {a.what}"); print(f"client point #{n} recorded")
    elif a.action == "list":
        for p in cl["pending"]:
            print(f"#{p['id']} [{p['kind']}] {p['what']} | cost: {p['price']} | by {p['by']}"
                  + (" OVERDUE" if p["by"] < today else "") + f" | default: {p['if_no_answer']}")
        print(f"{len(cl['pending'])} pending")
    elif a.action == "resolve":
        p = next((x for x in cl["pending"] if x["id"] == a.id), None) or die(f"no pending point #{a.id}")
        if not a.answer:
            die("--answer is required")
        cl["pending"].remove(p); cl["decided"].append({**p, "answer": a.answer, "by_default": False})
        save(r, s); journal(r, "client_resolve", f"#{p['id']} {a.answer}"); print("resolved")
    elif a.action == "report":
        cmd_client_report(r, s)
    elif a.action == "review":
        if a.phase not in TOUCHPOINTS:
            die(f"--phase must be one of {TOUCHPOINTS}")
        exp = r / ".forge" / "reviews" / f"{a.phase}.client.json"
        doc = (r / a.document).resolve()
        if Path(a.report).resolve() != exp.resolve() or not exp.is_file():
            die(f"the liaison report must be {exp.relative_to(r)}")
        if r / ".forge" not in doc.parents or not doc.is_file():
            die("--document must be an existing file inside .forge/ (the plain-language summary)")
        qs = json.loads(exp.read_text(encoding="utf-8")).get("questions")
        if not isinstance(qs, list):
            die("the report needs a 'questions' list")
        open_ = [q for q in qs if not str(q.get("resolution", "")).strip()]
        cl.setdefault("reviews", {})[a.phase] = {"document": str(doc.relative_to(r)), "doc_hash": sha(doc),
            "report_hash": sha(exp), "questions": len(qs), "unresolved": len(open_)}
        save(r, s); journal(r, "client_review", f"{a.phase} questions={len(qs)} unresolved={len(open_)}")
        print(f"client review of {a.phase}: {len(qs)} question(s), {len(open_)} without a resolution")
        sys.exit(1 if open_ else 0)
    elif a.action == "sweep":
        due = [p for p in cl["pending"] if p["by"] < today]
        for p in due:
            cl["pending"].remove(p)
            cl["decided"].append({**p, "answer": p["if_no_answer"], "by_default": True})
            journal(r, "client_default", f"#{p['id']} applied: {p['if_no_answer']}")
        save(r, s); print(f"{len(due)} overdue point(s) decided by default; report them at the next progress report")


# ---------------------------------------------------------------- rules audit (forge-rules)
RULES_DIRS = [".opencode/rules", ".cursor/rules", "rules", ".rules"]
ENTRY_FILES = ["AGENTS.md", "CLAUDE.md", ".github/copilot-instructions.md"]
VAGUE = [r"\b(carefully|properly|gracefully|robustly|cleanly|best practices?|make sure to|ensure that)\b",
         r"\b(as needed|where appropriate|as appropriate|when appropriate|if possible|where possible)\b",
         r"\b(should|might|try to|consider|ideally|preferably|generally|normally|usually|feel free)\b",
         r"(proprement|correctement|soigneusement|convenablement|adequatement|bien fait)",
         r"(si besoin|selon le cas|au besoin|le cas echeant|dans la mesure du possible)"]
HEDGE = [r"\b(probably|likely|presumably|more or less)\b[^\n]{0,60}\b(but|though|however|verify|confirm)\b",
         r"(probablement|sans doute|il me semble)[^\n]{0,60}\b(mais|cependant|toutefois|verifier)\b"]
GATES = {"lint": r"\blint\b|analyse statique", "typecheck": r"\btype-?check\b|\btypage\b",
         "tests": r"\btests?\b|suite de tests", "coverage": r"\bcoverage\b|\bcouverture\b",
         "duplication": r"\bduplication\b|copypaste|copie[- ]coller", "vulnerabilities": r"\bvulnerab",
         "review": r"\breview\b|\brevue\b|code review"}
THRESH = {"coverage": r"(\d+(?:[.,]\d+)?)\s*%\s*(?:of\s+|de\s+)?(?:test\s+)?(?:coverage|couverture)|(?:coverage|couverture)\s*(?:>=?|min(?:imum)?|threshold)?\s*[:=]?\s*(\d+(?:[.,]\d+)?)\s*%",
          "duplication": r"(\d+(?:[.,]\d+)?)\s*%\s*(?:of\s+|de\s+)?duplication|duplication\s*(?:<=?|max(?:imum)?|threshold)?\s*[:=]?\s*(\d+(?:[.,]\d+)?)\s*%",
          "file_size": r"(?:over|more than|above|plus de|au-dela de)\s+(\d{2,4})\s*(?:lines|lignes)|>\s*(\d{2,4})\s*(?:lines|lignes)"}
FOREIGN = [("flutter", r"\bflutter\b", "flutter"), ("riverpod", r"\bRiverpod\b", "flutter"),
           ("nextjs", r"\bNext\.js\b", "nextjs"), ("getServerSideProps", r"\bgetServerSideProps\b", "nextjs"),
           ("NgModule", r"\bNgModule\b", "angular"), ("RxJS", r"\bRxJS\b", "angular"),
           ("Spring Boot", r"\bSpring Boot\b", "spring"), ("JpaRepository", r"\bJpaRepository\b", "spring"),
           ("NestJS", r"\bNestJS\b", "nest"), ("jQuery", r"\bjQuery\b", None), ("shadcn", r"\bshadcn\b", None),
           ("Redux Toolkit", r"\bRedux Toolkit\b", None), ("Zustand", r"\bZustand\b", None)]
SELFREF = [r"\bper the profiles\b", r"\bthe profiles\b", r"\bthis profile\b", r"\bthe \w+ profile\b",
           r"\baccording to the template\b", r"\bsource profile\b", r"\.plan\.md", r"MIGRATION_ROADMAP",
           r"\breferences/templates\b"]
COUPLING = [r"\.forge\b", r"\bforge (init|status|gate|register|review|phase|memory|slice|client|design|check)\b",
            r"\bforge\.py\b", r"\bforge-(qa|redteam|analyst|designer|architect|builder)\b"]


def _deaccent(x):
    import unicodedata
    return "".join(c for c in unicodedata.normalize("NFD", x) if unicodedata.category(c) != "Mn")


def _noblock(text):
    return re.sub(re.escape("<!-- forge:start") + r".*?" + re.escape(END) + r"\n?", "", text, flags=re.S)


def _clean(text):
    return re.sub(r"`[^`\n]*`", lambda m: " " * len(m.group(0)), _noblock(text))


def _headnorm(s):
    s = _deaccent(s).lower()
    return re.sub(r"[^a-z0-9 ]+", " ", re.sub(r"^\d+[.)]?\s*", "", s.strip())).split()


def rules_load(root):
    rd = next((root / d for d in RULES_DIRS if (root / d).is_dir()), None)
    files = sorted(p for p in rd.rglob("*") if p.suffix in (".md", ".mdc")) if rd else []
    entry = next((root / e for e in ENTRY_FILES if (root / e).is_file()), None)
    return rd, files, entry


def stack_of(root):
    sig = set()
    if (root / "pubspec.yaml").is_file():
        sig.add("flutter")
    pj = root / "package.json"
    blob = pj.read_text(encoding="utf-8") if pj.is_file() else ""
    for f in ("pom.xml", "build.gradle", "build.gradle.kts"):
        if (root / f).is_file():
            blob += (root / f).read_text(encoding="utf-8")
    conv = root / ".forge" / "brief.md"
    if not blob and conv.is_file():
        blob = conv.read_text(encoding="utf-8")
    for k, pat in (("nextjs", r"\"next\"|next\.js"), ("angular", r"@angular/"), ("spring", r"spring-boot|springframework"),
                   ("nest", r"@nestjs/"), ("flutter", r"flutter"), ("react", r"\"react\"|react native|expo")):
        if re.search(pat, blob, re.I):
            sig.add(k)
    return sig


def rules_checks(root, target, budget):
    rd, files, entry = rules_load(root)
    texts = {f: f.read_text(encoding="utf-8") for f in files}
    etext = entry.read_text(encoding="utf-8") if entry else ""
    rel = lambda f: str(f.relative_to(root))
    allt = list(texts.items()) + ([(entry, etext)] if entry else [])
    res = []

    def add(name, offenders):
        res.append((name, offenders))

    # 1 wiring
    off = []
    if target == "opencode":
        cfgf = next((root / c for c in ("opencode.json", "opencode.jsonc", ".opencode/opencode.json") if (root / c).is_file()), None)
        if not cfgf:
            off.append("no opencode.json: the rule set is inert")
        else:
            try:
                ins = json.loads(cfgf.read_text(encoding="utf-8")).get("instructions")
            except ValueError:
                ins = None; off.append(f"{cfgf.name} is not valid JSON")
            if ins is not None and (not isinstance(ins, list) or not ins):
                off.append("no 'instructions' list: nothing is loaded")
            for pat in ins or []:
                if "*" in pat:
                    if not [p for p in root.glob(pat) if p.is_file()]:
                        off.append(f"glob '{pat}' matches nothing")
                elif not (root / pat).exists():
                    off.append(f"path '{pat}' does not exist")
            if entry and entry.name == "AGENTS.md" and ins and not any(i == "AGENTS.md" for i in ins):
                off.append("AGENTS.md exists but is not loaded by 'instructions'")
    elif target == "claude":
        cm = root / "CLAUDE.md"
        if not cm.is_file():
            off.append("no CLAUDE.md")
        elif (root / "AGENTS.md").is_file() and "@AGENTS.md" not in cm.read_text(encoding="utf-8"):
            off.append("CLAUDE.md does not import @AGENTS.md")
    elif not (root / "AGENTS.md").is_file():
        off.append("no AGENTS.md")
    add("wiring", off)

    # 2 index
    off = []
    rows = [l for l in etext.splitlines() if l.strip().startswith("|")]
    for f, tx in texts.items():
        rows += [l for l in tx.splitlines() if l.strip().startswith("|")] if re.search(r"\.mdc?\b", "".join(l for l in tx.splitlines() if l.strip().startswith("|"))) else []
    listed = {m for l in rows for m in re.findall(r"([\w./-]+\.mdc?)\b", l)}
    for f in files:
        if f.name not in {Path(x).name for x in listed}:
            off.append(f"{rel(f)} exists but is not listed in an index table")
    for x in sorted(listed):
        if not any((p / x).exists() for p in [root, rd or root]) and not any(f.name == Path(x).name for f in files) and not list(root.rglob(Path(x).name)):
            off.append(f"index lists '{x}', which does not exist")
    add("index", off)

    # 3 placeholders
    off = [f"{rel(f)}:{i}: placeholder" for f, tx in allt for i, l in enumerate(tx.splitlines(), 1)
           if re.search(r"\{\{[^}]*\}\}|\bTODO\b|\bTBD\b|\bFIXME\b|\bXXX\b|lorem ipsum|\[fill", l)]
    add("placeholders", off)

    # 4 cross references
    off = []
    heads = {f.name: [_headnorm(h) for h in re.findall(r"^#+\s*(.+)$", tx, re.M)] for f, tx in allt}
    for f, tx in allt:
        for fn, sec in re.findall(r"`?([\w./-]+\.mdc?)`?\s*§\s*([^\n|.;,)`]+)", tx):
            hs = heads.get(Path(fn).name)
            want = _headnorm(sec)
            if hs is None:
                off.append(f"{rel(f)}: reference to unknown file {fn}")
            elif not any(want and all(w in h for w in want) for h in hs):
                off.append(f"{rel(f)}: {fn} has no section '{sec.strip()}'")
    add("cross_references", off)

    # 5 thresholds
    seen = {}
    for f, tx in allt:
        body = _deaccent(tx)
        for k, pat in THRESH.items():
            for m in re.finditer(pat, body, re.I):
                v = next((g for g in m.groups() if g), None)
                if v:
                    seen.setdefault(k, {}).setdefault(float(v.replace(",", ".")), set()).add(rel(f))
    add("thresholds", [f"{k} has conflicting values {sorted(v)}" for k, v in seen.items() if len(v) > 1])

    # 6 coupling to the planning tool
    off = []
    for f, tx in allt:
        for i, l in enumerate(_noblock(tx).splitlines(), 1):
            if any(re.search(p, l) for p in COUPLING):
                off.append(f"{rel(f)}:{i}: rule text depends on Forge (rules must work without it)")
    add("no_forge_coupling", off)

    # 7 contamination
    sig = stack_of(root)
    off = []
    for f, tx in allt:
        body = _clean(tx)
        for i, l in enumerate(body.splitlines(), 1):
            for pat in SELFREF:
                if re.search(pat, l, re.I):
                    off.append(f"{rel(f)}:{i}: names its own source template or another project's vocabulary")
            if sig:
                for name, pat, eco in FOREIGN:
                    if re.search(pat, l, re.I if name in ("flutter",) else 0) and (eco is None or eco not in sig):
                        if eco is None and not sig:
                            continue
                        off.append(f"{rel(f)}:{i}: '{name}' is not part of the detected stack {sorted(sig)}")
    add("no_contamination", off)

    # 8 unenforceable prose
    off = []
    for f, tx in allt:
        for i, l in enumerate(_deaccent(_clean(tx)).splitlines(), 1):
            if re.match(r"^\s*\|?[\s|:-]*$", l):
                continue
            for pat in VAGUE + HEDGE:
                m = re.search(pat, l, re.I)
                if m:
                    off.append(f"{rel(f)}:{i}: '{m.group(0)[:30]}'")
    add("no_unenforceable_prose", off)

    # 9 gates are commands
    corpus = _deaccent("\n".join(tx for _, tx in allt))
    off = []
    for g, pat in GATES.items():
        lines = [l for l in corpus.splitlines() if re.search(pat, l, re.I)]
        if not lines:
            off.append(f"gate '{g}' is never mentioned")
        elif not any(re.search(r"`[^`]+`", l) for l in lines):
            off.append(f"gate '{g}' has no command in backticks on any line that names it")
    if not re.search(r"\bexit 0\b|\bsort 0\b|exit code|--threshold|--fail-on|--audit-level", corpus):
        off.append("no line states the pass condition (exit 0 or a threshold flag)")
    add("gates_are_commands", off)

    # 10 budget
    tot = sum(len(tx.splitlines()) for _, tx in allt)
    off = [f"{rel(f)} has {len(tx.splitlines())} lines (ceiling 500)" for f, tx in texts.items() if len(tx.splitlines()) > 500]
    if tot > budget:
        off.append(f"total {tot} lines exceeds the budget {budget} (a target without scoping loads every file every session)")
    add("budget", off)

    return res, tot


RULES_TARGETS = ("opencode", "claude", "agents")


def rules_hash(root):
    rd, files, entry = rules_load(root)
    h = hashlib.sha256()
    for f in ([entry] if entry else []) + files:
        txt = _noblock(f.read_text(encoding="utf-8")) if f == entry else f.read_text(encoding="utf-8")
        h.update(str(f.relative_to(root)).encode() + b"\0" + txt.encode("utf-8"))
    return h.hexdigest()[:16]


def rules_cfg(root, s):
    d = s["deliverables"].get("rules-report")
    txt = (root / d["path"]).read_text(encoding="utf-8") if d else ""
    t = re.search(r"^- target:\s*(\w+)", txt, re.M)
    b = re.search(r"^- budget:\s*(\d+)", txt, re.M)
    return (t.group(1) if t and t.group(1) in RULES_TARGETS else "opencode"), (int(b.group(1)) if b else 800)


def rules_gate_problems(root, s):
    if "rules-report" not in s["deliverables"]:
        return []
    target, budget = rules_cfg(root, s)
    res, tot = rules_checks(root, target, budget)
    return [f"rules audit ({target}, budget {budget}): {n}: {x}" for n, o in res for x in o[:5]]


def cmd_rules(a):
    root = Path(a.path).resolve()
    res, tot = rules_checks(root, a.target, a.budget)
    bad = [(n, o) for n, o in res if o]
    if a.json:
        print(json.dumps({n: o for n, o in res}, indent=2))
    else:
        for n, o in res:
            print(f"[{'FAIL' if o else 'ok  '}] {n}")
            for x in o[:15]:
                print("       -", x)
        print(f"{len(res) - len(bad)}/{len(res)} checks pass; total rule lines {tot}")
    sys.exit(1 if bad else 0)


# ---------------------------------------------------------------- kit integrity, client report
KITDIR = Path(__file__).resolve().parent.parent
KIT_DIRS = ("cli", "hooks", "skills", "agents", "scripts")


def kit_hashes(base):
    out = {}
    for d in KIT_DIRS:
        for p in sorted((base / d).rglob("*")) if (base / d).is_dir() else []:
            if p.is_file() and "__pycache__" not in p.parts:
                out[str(p.relative_to(base)).replace("\\", "/")] = hashlib.sha256(p.read_bytes()).hexdigest()
    return out


def kit_problems():
    m = KITDIR / "kit.sha256"
    if not m.is_file():
        return None
    exp, now_ = json.loads(m.read_text(encoding="utf-8")), kit_hashes(KITDIR)
    out = [f"{k}: modified" for k, v in exp.items() if k in now_ and now_[k] != v]
    out += [f"{k}: missing" for k in exp if k not in now_]
    out += [f"{k}: not part of the installed kit" for k in now_ if k not in exp]
    return out


def cmd_kit(a):
    pr = kit_problems()
    if pr is None:
        print("kit: no kit.sha256 next to this CLI (running from a source checkout, not an installed kit)"); return
    if pr:
        print("KIT MODIFIED"); [print("  -", x) for x in pr[:20]]; sys.exit(1)
    print("kit: every installed file matches the manifest")


def cmd_client_report(r, s):
    cl = s.setdefault("client", {"pending": [], "decided": []})
    last = cl.get("last_report", "")
    print(f"# Progress report data ({now()})\n")
    print("Write the client-facing report in the project language from these facts, then run the forge-client-liaison agent on it.\n")
    print(f"- project: {s['project']} | language: {s['lang']} | mode: {s['mode']}")
    print("- phases: " + ", ".join(f"{p}={s['phases'][p]}" for p in PHASES))
    appr = sorted(n for n, d in s["deliverables"].items() if s["phases"][d["phase"]] == "approved")
    print(f"- approved deliverables: {', '.join(appr) or 'none'}")
    print(f"- next action: {next_action(s, r)}")
    dec = mem(r, "decisions.md").read_text(encoding="utf-8")
    new = [b.split("\n", 1) for b in re.split(r"^## ", dec, flags=re.M)[1:]]
    new = [(h, body.strip().split("\n")[0]) for h, body in new if (re.search(r"\((\d{4}-[^)]+)\)", h) or [None, ""])[1] > last]
    print(f"- decisions taken for the client since the last report: {len(new)}")
    for h, body in new:
        print(f"    * {h.strip()}: {body}")
    byd = [x for x in cl["decided"] if x.get("by_default") and x.get("resolved_in_report") is None]
    print(f"- points decided by default (must be reported): {len(byd)}")
    for x in byd:
        print(f"    * #{x['id']} {x['what']} -> {x['answer']} (cost: {x['price']})")
        x["resolved_in_report"] = now()
    print(f"- points waiting for the client: {len(cl['pending'])}")
    for x in cl["pending"]:
        print(f"    * #{x['id']} {x['what']} | cost: {x['price']} | answer by {x['by']} | default: {x['if_no_answer']}")
    cl["last_report"] = now()
    save(r, s); journal(r, "client_report", "report data produced")


# ---------------------------------------------------------------- hooks
def cmd_hooks(a):
    r = need_root(); home = Path.home()
    found = []
    for f in (r / ".claude" / "settings.json", home / ".claude" / "settings.json"):
        if f.is_file() and "forge_hook" in f.read_text(encoding="utf-8"):
            found.append(f"claude-code: {f}")
    for f in (r / ".opencode" / "plugin" / "forge.ts", home / ".config" / "opencode" / "plugin" / "forge.ts"):
        if f.is_file():
            found.append(f"opencode: {f}")
    if found:
        print("hooks installed:"); [print("  " + x) for x in found]
    else:
        print("hooks NOT installed: memory runs in degraded mode (conditional triggers only)"); sys.exit(1)


# ---------------------------------------------------------------- lint
def cmd_lint(a):
    pat = re.compile("|".join(BANNED), re.I)
    hits = 0
    files = []
    for t in a.paths:
        p = Path(t)
        files += [p] if p.is_file() else sorted(p.rglob("*.md"))
    for f in files:
        txt = f.read_text(encoding="utf-8")
        if "lint:ignore-file" in txt and f.name == "banned-wording.md":
            continue  # the only file allowed to quote banned words: its job is to list them
        for i, line in enumerate(txt.splitlines(), 1):
            m = pat.search(line)
            if m:
                hits += 1; print(f"{f}:{i}: soft wording '{m.group(0)}'")
    print(f"{hits} soft-wording hit(s) in {len(files)} file(s)")
    sys.exit(1 if hits else 0)


def main():
    ap = argparse.ArgumentParser(prog="forge")
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("init"); p.add_argument("--name", required=True)
    p.add_argument("--lang", default="en"); p.add_argument("--path", default="."); p.set_defaults(f=cmd_init)
    sub.add_parser("status").set_defaults(f=cmd_status)
    p = sub.add_parser("mode"); p.add_argument("value", choices=["interactive", "client"]); p.add_argument("--evidence", default=""); p.set_defaults(f=cmd_mode)
    p = sub.add_parser("phase"); ps = p.add_subparsers(dest="sub", required=True)
    q = ps.add_parser("start"); q.add_argument("phase", choices=PHASES); q.set_defaults(f=cmd_phase_start)
    q = ps.add_parser("reopen"); q.add_argument("phase", choices=PHASES); q.add_argument("--reason", default=""); q.set_defaults(f=cmd_reopen)
    p = sub.add_parser("register"); p.add_argument("name"); p.add_argument("path")
    p.add_argument("--requires", default=""); p.set_defaults(f=cmd_register)
    p = sub.add_parser("review"); p.add_argument("name"); p.add_argument("--agent", required=True, choices=REVIEWERS)
    p.add_argument("--report", required=True); p.set_defaults(f=cmd_review)
    p = sub.add_parser("gate"); p.add_argument("action", choices=["check", "approve"])
    p.add_argument("--evidence", default=""); p.set_defaults(f=cmd_gate)
    p = sub.add_parser("memory"); p.add_argument("action", choices=["resume", "checkpoint", "decide", "learn", "log"])
    p.add_argument("--task", default=""); p.add_argument("--next", default="")
    p.add_argument("--files", default=""); p.add_argument("--blockers", default="")
    p.add_argument("--text", default=""); p.add_argument("--user-evidence", dest="user_evidence", default=""); p.set_defaults(f=cmd_memory)
    p = sub.add_parser("design"); p.add_argument("action", choices=["check"]); p.add_argument("--plans", action="store_true"); p.set_defaults(f=cmd_design)
    p = sub.add_parser("check"); p.add_argument("what", choices=["coverage", "premises", "plans"]); p.set_defaults(f=cmd_check)
    p = sub.add_parser("slice"); p.add_argument("action", choices=["start", "done"]); p.add_argument("id")
    p.add_argument("--evidence", default=""); p.set_defaults(f=cmd_slice)
    p = sub.add_parser("client"); p.add_argument("action", choices=["ask", "list", "resolve", "sweep", "report", "review"])
    p.add_argument("--kind", default="decision", choices=["decision", "deviation"]); p.add_argument("--what", default="")
    p.add_argument("--price", default=""); p.add_argument("--by", default=""); p.add_argument("--if-no-answer", dest="if_no_answer", default="")
    p.add_argument("--id", type=int, default=0); p.add_argument("--answer", default="")
    p.add_argument("--phase", default=""); p.add_argument("--document", default=""); p.add_argument("--report", default=""); p.set_defaults(f=cmd_client)
    p = sub.add_parser("rules"); p.add_argument("action", choices=["audit"]); p.add_argument("path", nargs="?", default=".")
    p.add_argument("--target", default="opencode", choices=["opencode", "claude", "agents"])
    p.add_argument("--budget", type=int, default=800); p.add_argument("--json", action="store_true"); p.set_defaults(f=cmd_rules)
    p = sub.add_parser("kit"); p.add_argument("action", choices=["verify"]); p.set_defaults(f=cmd_kit)
    p = sub.add_parser("hooks"); p.add_argument("action", choices=["status"]); p.set_defaults(f=cmd_hooks)
    p = sub.add_parser("lint-rules"); p.add_argument("paths", nargs="+"); p.set_defaults(f=cmd_lint)
    a = ap.parse_args()
    if a.cmd == "memory" and a.action in ("decide", "learn", "log") and not a.text:
        die("--text is required")
    if a.cmd == "memory" and a.action == "checkpoint" and not (a.task and a.next):
        die("--task and --next are required")
    a.f(a)


if __name__ == "__main__":
    main()
