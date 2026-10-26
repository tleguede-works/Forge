#!/usr/bin/env bash
# The human tracker is a derived view: deterministic, regenerated from the state, never evidence.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
import pathlib, subprocess, sys, tempfile
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

cwd = pathlib.Path(tempfile.mkdtemp(prefix="forge-prog-"))
assert run(cwd, "init", "--name", "Prog").returncode == 0
tracker = cwd / ".forge" / "progress.md"

# --- A. the phase table is the executable registry -------------------------------------
first = tracker.read_text(encoding="utf-8")
check(run(cwd, "progress", "--check").returncode == 0, "the tracker is generated at init")
for ph in forge.PHASES:
    check(f"| {ph} |" in first and f"`{forge.PHASE_SKILL[ph]}`" in first
          and f"`{forge.PHASE_PRODUCER[ph]}`" in first, f"the phase table names the skill and producer of {ph}")
check(first == forge.progress_text(cwd, forge.load(cwd)), "the file matches the generator byte for byte")
run(cwd, "progress")
check(run(cwd, "progress", "--check").returncode == 0, "regenerating with no change keeps it valid")

# --- B. slices, waves and evidence come from the files ----------------------------------
for ph in forge.PHASES[:forge.PHASES.index("build")]:
    mutate(cwd, f"s['phases']['{ph}']='approved'")
mutate(cwd, "s['phases']['build']='in_progress'; s['phase']['current']='build'; "
            "s['slices']={'S01':'pending','S02':'pending'}; s['slice_evidence']={'S01':'pytest tests/a.py : 4 passed'}")
(cwd / ".forge" / "slices.md").write_text(
    "| id | name | module | serves |\n|---|---|---|---|\n"
    "| S01 | App shell | foundation | C1 |\n| S02 | Card payment | billing | B1 |\n", encoding="utf-8")
(cwd / ".forge" / "plans").mkdir(parents=True, exist_ok=True)
(cwd / ".forge" / "plans" / "index.md").write_text(
    "| order | slice | plan file | depends on | release |\n|---|---|---|---|---|\n"
    "| 1 | S01 | `.forge/plans/S01.md` | none | MVP |\n"
    "| 2 | S02 | `.forge/plans/S02.md` | S01 | R2 |\n", encoding="utf-8")
(cwd / ".forge" / "plans" / "S01.md").write_text(
    "# S01\n## 3. Tasks {#tasks}\n- [x] T1 shell | files: a | result: b\n- [ ] T2 nav | files: c | result: d\n"
    "## 4. Acceptance {#acceptance}\n1. The shell renders on a 360 px screen (C1)\n"
    "## 5. Test cases {#test-cases}\n- TC-S01-1 | verifies C1 | input: 360 | expected: no overflow\n",
    encoding="utf-8")
run(cwd, "progress")
txt = tracker.read_text(encoding="utf-8")
check("### MVP" in txt and "### R2" in txt, "one wave per release of the plans index")
check("| 1 | S01 — App shell | pending | 1/2 | `pytest tests/a.py : 4 passed` |" in txt,
      "a wave row carries status, task count and evidence")
check("### S02 — Card payment — pending" in txt and "plan missing" in txt,
      "a slice with no plan says so instead of inventing content")
check("TC-S01-1" in txt and "The shell renders on a 360 px screen" in txt,
      "the detail lists the acceptance criteria and the test cases a human can check")
check("next action:" in txt and run(cwd, "status").stdout.split("next:")[-1].strip() in txt,
      "the tracker repeats the next action of forge status")

# --- C. a hand edit is detected, a regeneration repairs it ------------------------------
tracker.write_text(txt.replace("| 2 | S02 — Card payment | pending |",
                               "| 2 | S02 — Card payment | done |"),
                   encoding="utf-8")
r = run(cwd, "progress", "--check")
check(r.returncode != 0 and "stale or was edited" in r.stdout, "a hand-edited tracker is refused", r.stdout.strip())
run(cwd, "progress")
check(run(cwd, "progress", "--check").returncode == 0, "regeneration repairs the tracker")

# --- D. the gates regenerate instead of trusting the file -------------------------------
mutate(cwd, "s['slices']['S02']='done'")
tracker.write_text("everything is done, trust me\n", encoding="utf-8")
out = run(cwd, "gate", "check").stdout + run(cwd, "gate", "check").stderr
check("progress.md" not in out, "the build gate does not refuse a stale tracker: it rewrites it", out.strip()[:160])
check("everything is done" not in tracker.read_text(encoding="utf-8"),
      "the build gate replaced the hand-written tracker with the derived text")

# --- E. removing every slice keeps the file valid --------------------------------------
mutate(cwd, "s['slices']={}; s['slice_evidence']={}")
(cwd / ".forge" / "slices.md").unlink()
(cwd / ".forge" / "plans" / "index.md").unlink()
run(cwd, "progress")
txt = tracker.read_text(encoding="utf-8")
check("No slice exists yet" in txt and "Nothing to detail yet" in txt,
      "an empty project produces a readable tracker, not an empty file")

print()
print("PROGRESS PASS" if not bad else "PROGRESS FAIL")
for b in bad:
    print(" -", b)
sys.exit(1 if bad else 0)
PY
