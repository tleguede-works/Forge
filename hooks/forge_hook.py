#!/usr/bin/env python3
"""Hook entry for Claude Code. Usage: forge_hook.py session-start | pre-compact | post-tool
Reads the hook JSON from stdin. Silent when the directory is not a Forge project."""
import json, subprocess, sys
from pathlib import Path

EDIT_LIMIT = 10
CLI = str(Path(__file__).resolve().parent.parent / "cli" / "forge.py")


def root_from(cwd):
    p = Path(cwd).resolve()
    for d in [p, *p.parents]:
        if (d / ".forge" / "state.json").is_file():
            return d
    return None


def main():
    event = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        data = json.load(sys.stdin)
    except Exception:
        data = {}
    root = root_from(data.get("cwd") or ".")
    if root is None:
        return 0
    mem = root / ".forge" / "memory"
    if event == "session-start":
        out = subprocess.run([sys.executable, CLI, "memory", "resume"], cwd=root, capture_output=True, text=True)
        print("Forge memory (read before acting):\n" + out.stdout)
        return 0
    if event == "pre-compact":
        subprocess.run([sys.executable, CLI, "memory", "log", "--text", "context compaction started"], cwd=root)
        return 0
    if event == "post-tool":
        f = mem / ".edits"
        n = int(f.read_text() or 0) if f.exists() else 0
        n += 1
        f.write_text(str(n))
        if n >= EDIT_LIMIT:
            f.write_text("0")
            print(f"Forge: {EDIT_LIMIT} file edits since the last checkpoint. "
                  "Run `forge memory checkpoint --task ... --next ...` now.", file=sys.stderr)
            return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
