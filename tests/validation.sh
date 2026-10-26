#!/usr/bin/env bash
# The validation gate reads the report instead of trusting its existence: every test case the
# plans define needs a real result row, and every piece of evidence must be runnable.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
import json, pathlib, re, subprocess, sys, tempfile
root = pathlib.Path(sys.argv[1]); sys.path.insert(0, str(root / "cli")); import forge
CLI, PY_ = str(root / "cli" / "forge.py"), sys.executable
bad = []

def check(cond, label, extra=""):
    if not cond:
        bad.append(f"{label} {extra}".strip())
    print(("ok   " if cond else "FAIL ") + label)

def run(cwd, *args):
    return subprocess.run([PY_, CLI, *args], cwd=cwd, capture_output=True, text=True)

def mutate(cwd, code):
    snippet = ("import sys; sys.path.insert(0, %r); import forge; R = forge.find_root(); "
               "s = forge.load(R); %s; forge.save(R, s)" % (str(root / "cli"), code))
    p = subprocess.run([PY_, "-c", snippet], cwd=cwd, capture_output=True, text=True)
    assert p.returncode == 0, p.stderr

def fresh(name):
    d = pathlib.Path(tempfile.mkdtemp(prefix="forge-val-"))
    assert run(d, "init", "--name", name).returncode == 0
    return d

REPORT = ("# Report\n## 1. Test plan results {#test-plan-results}\n"
          "| test case | verifies | command | result | evidence |\n|---|---|---|---|---|\n")
TAIL = ("## 2. Deviations from the plans and the PRD {#deviations-from-the-plans-and-the-prd}\n"
        "None; no deviation was found.\n"
        "## 3. Requirements not met {#requirements-not-met}\nNone; every requirement is met.\n"
        "## 4. Acceptance summary {#acceptance-summary}\nDelivered, tested and accepted.\n")

# --- A. a deliverable has to carry text, not a placeholder -----------------------------
cwd = fresh("Structure")
mutate(cwd, "s['phases']['bootstrap']='approved'; s['phases']['landscape']='approved'; "
            "s['phases']['compliance']='approved'; s['phases']['prd']='in_progress'; "
            "s['phases']['prd']='in_progress'; s['phase']['current']='prd'")
hollow = "\n".join(f"## {k}\nx" for k in forge.HEADINGS["prd"])
(pathlib.Path(cwd) / ".forge" / "prd.md").write_text(hollow, encoding="utf-8")
r = run(cwd, "register", "prd", ".forge/prd.md")
check(r.returncode != 0 and "character(s) of text" in r.stderr,
      "a one-character section is refused", r.stderr.strip()[:120])
tpl = run(cwd, "template", "prd").stdout
leak = re.sub(r"<fill>", "sample text", tpl) + "\n- B1 <rule> (source: user-stated)\n"
(pathlib.Path(cwd) / ".forge" / "prd.md").write_text(leak, encoding="utf-8")
r = run(cwd, "register", "prd", ".forge/prd.md")
check(r.returncode != 0 and "placeholder" in r.stderr, "a template token is refused", r.stderr.strip()[:120])
good = re.sub(r"<fill>", "sample text", tpl).replace(
    "## 4. Business rules {#business-rules}\n",
    "## 4. Business rules {#business-rules}\n- B1 a card payment is captured at checkout (source: user-stated)\n", 1)
(pathlib.Path(cwd) / ".forge" / "prd.md").write_text(good, encoding="utf-8")
r = run(cwd, "register", "prd", ".forge/prd.md")
check(r.returncode == 0, "a sourced requirement registers", r.stderr.strip()[:120])
(pathlib.Path(cwd) / ".forge" / "prd.md").write_text(good.replace(" (source: user-stated)", ""),
                                                     encoding="utf-8")
r = run(cwd, "check", "prd")
check(r.returncode != 0 and "no source" in (r.stdout + r.stderr),
      "a requirement with no source is refused", (r.stdout + r.stderr).strip()[:120])
(pathlib.Path(cwd) / ".forge" / "prd.md").write_text(
    good.replace("a card payment is captured at checkout", "x"), encoding="utf-8")
r = run(cwd, "check", "prd")
check("character(s)" in (r.stdout + r.stderr), "a one-word requirement is refused",
      (r.stdout + r.stderr).strip()[:120])

# --- B. a ticked task is progress, not a change of content -----------------------------
cwd = fresh("Ticks")
for ph in forge.PHASES[:forge.PHASES.index("plans")]:
    mutate(cwd, f"s['phases']['{ph}']='approved'")
mutate(cwd, "s['phases']['plans']='in_progress'; s['phase']['current']='plans'")
(pathlib.Path(cwd) / ".forge" / "slices.md").write_text(
    "| id | name | module | serves |\n|---|---|---|---|\n| S01 | Pay | billing | B1 |\n", encoding="utf-8")
plan = ("# S01 Pay\n## 1. Serves {#serves}\n- serves: B1\n"
        "## 2. Contract {#contract}\nInputs a payment form, outputs a receipt.\n"
        "## 3. Tasks {#tasks}\n- [ ] T1 write the failing test | files: tests/test_pay.py | result: it fails\n"
        "## 4. Acceptance {#acceptance}\n1. A card payment returns a receipt (B1)\n"
        "## 5. Test cases {#test-cases}\n- TC-S01-1 | verifies B1 | input: 4242 | expected: receipt\n")
p = pathlib.Path(cwd) / ".forge" / "plans" / "S01.md"; p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(plan, encoding="utf-8")
r = run(cwd, "register", "plan:S01", ".forge/plans/S01.md")
check(r.returncode == 0, "a complete plan registers", r.stderr.strip()[:160])
p.write_text(plan.replace("- [ ]", "- [x]"), encoding="utf-8")
check("DRIFT" not in run(cwd, "status").stdout, "ticking a task is not drift")

# --- C. evidence has to be a command and a result --------------------------------------
(pathlib.Path(cwd) / ".forge" / "plans" / "index.md").write_text(
    "| order | slice | plan file | depends on | release |\n|---|---|---|---|---|\n"
    "| 1 | S01 | `.forge/plans/S01.md` | none | MVP |\n", encoding="utf-8")
run(cwd, "register", "plans-index", ".forge/plans/index.md")
(pathlib.Path(cwd) / ".forge" / "test-plan.md").write_text(
    "## 1. Strategy {#strategy}\nUnit tests with pytest.\n"
    "## 2. Coverage matrix {#coverage-matrix}\n| PRD ID | Slice | Test case | Level |\n"
    "|---|---|---|---|\n| B1 | S01 | TC-S01-1 | unit |\n"
    "## 3. Regression set {#regression-set}\n- command: `pytest`\n"
    "## 4. Environments and data {#environments-and-data}\nLocal sqlite file.\n", encoding="utf-8")
run(cwd, "register", "test-plan", ".forge/test-plan.md")
mutate(cwd, "s['phases']['plans']='approved'")
run(cwd, "phase", "start", "build")
(pathlib.Path(cwd) / "tests").mkdir()
(pathlib.Path(cwd) / "tests" / "test_pay.py").write_text("def test_pay():\n    pass\n", encoding="utf-8")
run(cwd, "slice", "start", "S01")
for ev, why in (("pytest tests/missing.py : 4 passed", "names a file that does not exist"),
                ("yesterday it worked : 4 passed", "names no test runner"),
                ("pytest tests/test_pay.py : looks fine", "states no count and no verdict")):
    r = run(cwd, "slice", "done", "S01", "--evidence", ev)
    check(r.returncode != 0, f"evidence that {why} is refused", r.stderr.strip()[:100])
r = run(cwd, "slice", "done", "S01", "--evidence", "pytest tests/test_pay.py : 4 passed")
check(r.returncode == 0, "runnable evidence is accepted", r.stderr.strip()[:160])
state = json.loads((pathlib.Path(cwd) / ".forge" / "state.json").read_text())
check(state.get("slice_evidence", {}).get("S01", "").startswith("pytest"),
      "the evidence is kept in the state, not only in a journal line")
mutate(cwd, "s['phases']['build']='approved'")
r = run(cwd, "phase", "start", "validation")
check(r.returncode == 0, "validation is reachable once the build is done", r.stderr.strip()[:160])

# --- D. the report is compared with the plan -------------------------------------------
rep = pathlib.Path(cwd) / ".forge" / "validation-report.md"
(pathlib.Path(cwd) / ".forge" / "prd.md").write_text(
    "# PRD\n## 4. Business rules {#business-rules}\n- B1 a card payment is captured (source: user-stated)\n",
    encoding="utf-8")
rep.write_text(REPORT + "| TC-S01-1 | B1 | pytest tests/test_pay.py | pass | pass |\n" + TAIL,
               encoding="utf-8")
s = forge.load(cwd)
check(any("no evidence" in x for x in forge.validation_problems(cwd, s)),
      "a results row with no evidence is refused", forge.validation_problems(cwd, s))
rep.write_text(REPORT + "| TC-S01-1 | B1 | ran it myself | pass | the whole suite printed 4 passed |\n" + TAIL,
               encoding="utf-8")
check(any("not a test command" in x for x in forge.validation_problems(cwd, s)),
      "a command that is not a test command is refused", forge.validation_problems(cwd, s))
rep.write_text(REPORT + "| TC-S01-1 | B9 | pytest tests/test_pay.py | pass | 4 passed |\n" + TAIL,
               encoding="utf-8")
check(any("does not define" in x for x in forge.validation_problems(cwd, s)),
      "a row that verifies an unknown requirement is refused", forge.validation_problems(cwd, s))
rep.write_text(REPORT + "| TC-S01-1 | B1 | pytest tests/test_pay.py | pass | 4 passed in 0.2s |\n" + TAIL,
               encoding="utf-8")
check(forge.validation_problems(cwd, s) == [], "a complete report passes",
      forge.validation_problems(cwd, s))
(pathlib.Path(cwd) / ".forge" / "plans" / "S01.md").write_text(
    plan.replace("- [ ]", "- [x]").replace("TC-S01-1", "TC-S01-1\n- TC-S01-2"), encoding="utf-8")
check(any("TC-S01-2" in x for x in forge.validation_problems(cwd, s)),
      "a test case with no result row is refused", forge.validation_problems(cwd, s))

print()
print("VALIDATION PASS" if not bad else "VALIDATION FAIL")
for b in bad:
    print(" -", b)
sys.exit(1 if bad else 0)
PY
