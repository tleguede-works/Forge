#!/usr/bin/env python3
"""Forge installer. Copies the kit to ~/.forge and wires Claude Code and/or OpenCode.
Usage: install.py [--src DIR] [--target auto|claude|opencode|both] [--uninstall]
Everything it creates is listed in ~/.forge/install-manifest.json so --uninstall can remove it."""
import argparse, json, os, re, shutil, stat, sys
from pathlib import Path

HOME = Path(os.environ.get("HOME") or os.environ.get("USERPROFILE") or Path.home())
KIT = HOME / ".forge"
MANIFEST = KIT / "install-manifest.json"
WIN = os.name == "nt"


def log(m):
    print("forge-install:", m)


def split_fm(text):
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    return (m.group(1), m.group(2)) if m else ("", text)


def convert_agent(name, text, target):
    fm, body = split_fm(text)
    if target == "opencode":
        return text
    lines = [l for l in fm.splitlines() if not l.startswith("mode:")]
    return "---\nname: " + name + "\n" + "\n".join(lines) + "\n---\n" + body


def copy_dir(src, dst, created):
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst, ignore=shutil.ignore_patterns("__pycache__"))
    created.append(str(dst))


def hook_cmds():
    py, hook = sys.executable, KIT / "hooks" / "forge_hook.py"
    return {ev: f'"{py}" "{hook}" {arg}' for ev, arg in
            (("SessionStart", "session-start"), ("PreCompact", "pre-compact"), ("PostToolUse", "post-tool"))}


def strip_forge_hooks(cfg):
    for ev in list(cfg.get("hooks", {})):
        kept = []
        for group in cfg["hooks"][ev]:
            group["hooks"] = [h for h in group.get("hooks", []) if "forge_hook" not in h.get("command", "")]
            if group["hooks"]:
                kept.append(group)
        if kept:
            cfg["hooks"][ev] = kept
        else:
            del cfg["hooks"][ev]
    if not cfg.get("hooks"):
        cfg.pop("hooks", None)


def edit_claude_settings(add):
    f = HOME / ".claude" / "settings.json"
    cfg = json.loads(f.read_text(encoding="utf-8")) if f.exists() else {}
    strip_forge_hooks(cfg)
    if add:
        for ev, cmd in hook_cmds().items():
            group = {"hooks": [{"type": "command", "command": cmd}]}
            if ev == "PostToolUse":
                group["matcher"] = "Write|Edit|MultiEdit"
            cfg.setdefault("hooks", {}).setdefault(ev, []).append(group)
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text(json.dumps(cfg, indent=2) + "\n", encoding="utf-8")


def detect():
    t = []
    if (HOME / ".claude").exists() or shutil.which("claude"):
        t.append("claude")
    if (HOME / ".config" / "opencode").exists() or shutil.which("opencode"):
        t.append("opencode")
    return t


def install(src, target):
    created = []
    targets = detect() if target == "auto" else (["claude", "opencode"] if target == "both" else [target])
    if not targets:
        sys.exit("forge-install: neither Claude Code nor OpenCode found; use --target claude|opencode|both")
    KIT.mkdir(parents=True, exist_ok=True)
    for d in ("cli", "hooks", "skills", "agents", "scripts"):
        shutil.rmtree(KIT / d, ignore_errors=True)
        shutil.copytree(src / d, KIT / d, ignore=shutil.ignore_patterns("__pycache__"))
    cli = KIT / "cli" / "forge.py"
    cli.chmod(cli.stat().st_mode | stat.S_IEXEC)
    if WIN:
        b = KIT / "bin"; b.mkdir(exist_ok=True)
        (b / "forge.cmd").write_text(f'@echo off\r\n"{sys.executable}" "{cli}" %*\r\n')
        created.append(str(b / "forge.cmd"))
        log(f"add {b} to your PATH to run `forge` (install.ps1 does this)")
    else:
        lb = HOME / ".local" / "bin"; lb.mkdir(parents=True, exist_ok=True)
        link = lb / "forge"
        if link.is_symlink() or link.exists():
            link.unlink()
        link.symlink_to(cli); created.append(str(link))
        if str(lb) not in os.environ.get("PATH", ""):
            log(f"add {lb} to your PATH to run `forge`")
    skills = [p for p in (KIT / "skills").iterdir() if p.is_dir()]
    agents = sorted((KIT / "agents").glob("*.md"))
    for t in targets:
        if t == "claude":
            base = HOME / ".claude"
            for s in skills:
                copy_dir(s, base / "skills" / s.name, created)
            (base / "agents").mkdir(parents=True, exist_ok=True)
            for a in agents:
                dst = base / "agents" / a.name
                dst.write_text(convert_agent(a.stem, a.read_text(encoding="utf-8"), "claude"), encoding="utf-8")
                created.append(str(dst))
            edit_claude_settings(True)
            log("claude: skills, agents, hooks installed (settings.json hooks merged)")
        else:
            base = HOME / ".config" / "opencode"
            for s in skills:
                copy_dir(s, base / "skills" / s.name, created)
            (base / "agents").mkdir(parents=True, exist_ok=True)
            for a in agents:
                dst = base / "agents" / a.name
                dst.write_text(convert_agent(a.stem, a.read_text(encoding="utf-8"), "opencode"), encoding="utf-8")
                created.append(str(dst))
            (base / "plugin").mkdir(parents=True, exist_ok=True)
            plug = base / "plugin" / "forge.ts"
            shutil.copy(KIT / "hooks" / "opencode-forge.ts", plug); created.append(str(plug))
            log("opencode: skills, agents, plugin installed")
    MANIFEST.write_text(json.dumps({"targets": targets, "created": created}, indent=2), encoding="utf-8")
    log("done. Open a project and run: forge init --name <Name> --lang <code>")


def uninstall():
    if MANIFEST.exists():
        m = json.loads(MANIFEST.read_text(encoding="utf-8"))
        for p in map(Path, m["created"]):
            if p.is_dir():
                shutil.rmtree(p, ignore_errors=True)
            elif p.exists() or p.is_symlink():
                p.unlink()
        if "claude" in m["targets"]:
            edit_claude_settings(False)
        for d in [HOME/".claude"/"skills", HOME/".claude"/"agents", HOME/".config"/"opencode"/"skills",
                  HOME/".config"/"opencode"/"agents", HOME/".config"/"opencode"/"plugin"]:
            if d.is_dir() and not any(d.iterdir()):
                d.rmdir()
    shutil.rmtree(KIT, ignore_errors=True)
    log("uninstalled")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=str(Path(__file__).resolve().parent.parent))
    ap.add_argument("--target", default="auto", choices=["auto", "claude", "opencode", "both"])
    ap.add_argument("--uninstall", action="store_true")
    a = ap.parse_args()
    if sys.version_info < (3, 9):
        sys.exit("forge-install: Python 3.9 or newer is required")
    uninstall() if a.uninstall else install(Path(a.src), a.target)
