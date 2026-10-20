#!/usr/bin/env python3
"""Hook entry for Claude Code. Usage: forge_hook.py session-start | pre-compact | pre-task | post-tool
Reads the hook JSON from stdin. Silent when the directory is not a Forge project.
It never fails the host: any unexpected error ends with exit code 0. Exit code 2 is used on purpose, to block a
repeated subagent launch (pre-task) and to hand a message to the model (post-tool)."""
import hashlib, json, subprocess, sys
from pathlib import Path

EDIT_LIMIT = 10          # file edits between two checkpoints
SAME_FILE_LIMIT = 6      # edits of one file between two checkpoints
SAME_LAUNCH_LIMIT = 3    # identical subagent launches while the Forge state does not change
CLI = str(Path(__file__).resolve().parent.parent / "cli" / "forge.py")


def root_from(cwd):
    p = Path(cwd).resolve()
    for d in [p, *p.parents]:
        if (d / ".forge" / "state.json").is_file():
            return d
    return None


def load_json(path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default


def pre_task(root, data):
    ti = data.get("tool_input") or {}
    prompt = " ".join(str(ti.get("prompt", "")).split())[:600]
    key = hashlib.sha256((str(ti.get("subagent_type", "")) + "\0" + prompt).encode("utf-8")).hexdigest()[:16]
    seal = load_json(root / ".forge" / "state.json", {}).get("seal", "")
    f = root / ".forge" / "memory" / ".launches.json"
    book = load_json(f, {})
    if book.get("seal") != seal:
        book = {"seal": seal, "counts": {}}
    book["counts"][key] = book["counts"].get(key, 0) + 1
    try:
        f.write_text(json.dumps(book))
    except OSError:
        pass
    if book["counts"][key] >= SAME_LAUNCH_LIMIT:
        print(f"Forge loop guard: this subagent was launched {book['counts'][key]} times with the same request and the Forge "
              "state did not change. Stop launching it. Run `forge attempts`, write down what blocks and what you already tried, "
              "and if information is missing ask the user. Launch it again only after something changed "
              "(a file, a decision, an answer).", file=sys.stderr)
        return 2
    return 0


def post_tool(root, data):
    mem = root / ".forge" / "memory"
    f = mem / ".edits"
    try:
        n = int(f.read_text() or 0) if f.exists() else 0
    except ValueError:
        n = 0
    n += 1
    f.write_text(str(n))
    path = str((data.get("tool_input") or {}).get("file_path") or "")
    messages = []
    if path:
        fc = mem / ".filecounts.json"
        counts = load_json(fc, {})
        counts[path] = counts.get(path, 0) + 1
        if counts[path] >= SAME_FILE_LIMIT:
            messages.append(f"Forge loop guard: {path} was edited {counts[path]} times since the last checkpoint. "
                            "Stop and analyze: what do these edits have in common, what keeps failing, what information is missing? "
                            "Ask the user if the answer is not in the files; otherwise change the approach before editing again.")
            counts[path] = 0
        try:
            fc.write_text(json.dumps(counts))
        except OSError:
            pass
    if n >= EDIT_LIMIT:
        f.write_text("0")
        messages.append(f"Forge: {EDIT_LIMIT} file edits since the last checkpoint. Run `forge memory checkpoint --task ... --next ...` now.")
    if messages:
        print("\n".join(messages), file=sys.stderr)
        return 2
    return 0


def main():
    event = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        data = json.load(sys.stdin)
    except Exception:
        data = {}
    root = root_from(data.get("cwd") or ".")
    if root is None:
        return 0
    if event == "session-start":
        out = subprocess.run([sys.executable, CLI, "memory", "resume"], cwd=root, capture_output=True, text=True, timeout=20)
        try:
            print("Forge memory (read before acting):\n" + out.stdout)
        except BrokenPipeError:
            pass
        return 0
    if event == "pre-compact":
        subprocess.run([sys.executable, CLI, "memory", "log", "--text", "context compaction started"], cwd=root, timeout=20)
        return 0
    if event == "pre-task":
        return pre_task(root, data)
    if event == "post-tool":
        return post_tool(root, data)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
