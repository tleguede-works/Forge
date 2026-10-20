#!/usr/bin/env python3
"""Forge installer. Two scopes:
  global  the kit lives in ~/.forge and is wired into the user-level folders of Claude Code and OpenCode;
  local   the kit lives in <project>/.forge/kit and is wired into the project's .claude and .opencode folders.
Usage: install.py [--scope global|local] [--project DIR] [--target auto|claude|opencode|both] [--src DIR] [--uninstall]
Without --scope the installer asks (from the terminal); with no terminal it installs globally.
Everything it creates is listed in <kit>/install-manifest.json so --uninstall removes exactly that."""
import argparse, hashlib, json, os, re, shutil, stat, sys
from pathlib import Path

HOME = Path(os.environ.get("HOME") or os.environ.get("USERPROFILE") or Path.home())
WIN = os.name == "nt"
KIT_DIRS = ("cli", "hooks", "skills", "agents", "scripts")


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


class Scope:
    def __init__(self, kind, project=None):
        self.kind, self.project = kind, project
        if kind == "local":
            self.kit, self.claude = project / ".forge" / "kit", project / ".claude"
            self.opencode, self.bin = project / ".opencode", project / ".forge" / "bin"
            self.cmd = ".forge\\bin\\forge.cmd" if WIN else ".forge/bin/forge"
        else:
            self.kit, self.claude = HOME / ".forge", HOME / ".claude"
            self.opencode = HOME / ".config" / "opencode"
            self.bin = (self.kit / "bin") if WIN else HOME / ".local" / "bin"
            self.cmd = "forge"
        self.manifest = self.kit / "install-manifest.json"
        self.settings = self.claude / "settings.json"

    def hook_commands(self):
        if self.kind == "local":
            py = "python" if WIN else "python3"
            hook = '"$CLAUDE_PROJECT_DIR/.forge/kit/hooks/forge_hook.py"'
            pre = f"{py} {hook}"
        else:
            pre = f'"{sys.executable}" "{self.kit / "hooks" / "forge_hook.py"}"'
        return {ev: f"{pre} {arg}" for ev, arg in
                (("SessionStart", "session-start"), ("PreCompact", "pre-compact"),
                 ("PreToolUse", "pre-task"), ("PostToolUse", "post-tool"))}

    def rel(self, p):
        return str(p.relative_to(self.project)).replace("\\", "/") if self.kind == "local" else str(p)

    def absolute(self, s):
        return (self.project / s) if self.kind == "local" else Path(s)


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


def edit_claude_settings(sc, add):
    f = sc.settings
    existed = f.exists()
    cfg = json.loads(f.read_text(encoding="utf-8")) if existed else {}
    strip_forge_hooks(cfg)
    if add:
        for ev, cmd in sc.hook_commands().items():
            group = {"hooks": [{"type": "command", "command": cmd}]}
            if ev == "PostToolUse":
                group["matcher"] = "Write|Edit|MultiEdit"
            if ev == "PreToolUse":
                group["matcher"] = "Task"
            cfg.setdefault("hooks", {}).setdefault(ev, []).append(group)
    if not add and not cfg and not existed:
        return
    if not add and not cfg:
        f.unlink()
        return
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text(json.dumps(cfg, indent=2) + "\n", encoding="utf-8")
    return not existed


def detect(sc):
    has = shutil.which
    if sc.kind == "local":
        p = sc.project
        marks = {"claude": (p / ".claude").exists(),
                 "opencode": (p / ".opencode").exists() or (p / "opencode.json").exists()}
        found = [t for t, v in marks.items() if v]
        if found:
            return found
    return [t for t, v in (("claude", (HOME / ".claude").exists() or has("claude")),
                           ("opencode", (HOME / ".config" / "opencode").exists() or has("opencode"))) if v]


def prompt_scope():
    text = ("\nWhere should Forge be installed?\n"
            "  1) Global: once for this machine, available in every project (~/.forge)\n"
            "  2) Local:  inside the current project only (.forge/kit, .claude, .opencode)\n")
    stream = None
    if sys.stdin and sys.stdin.isatty():
        stream = sys.stdin
    else:
        try:
            stream = open("CONIN$" if WIN else "/dev/tty")
        except OSError:
            stream = None
    if stream is None:
        log("no terminal to ask on: installing globally (pass --scope local for a project install)")
        return "global"
    print(text + "Choice [1]: ", end="", flush=True)
    ans = stream.readline().strip().lower()
    return "local" if ans in ("2", "l", "local") else "global"


def hashes_of(files):
    return {f: hashlib.sha256(Path(f).read_bytes()).hexdigest() for f in files}


def install(sc, src, target):
    created, installed = [], []
    targets = detect(sc) if target == "auto" else (["claude", "opencode"] if target == "both" else [target])
    if not targets:
        sys.exit("forge-install: neither Claude Code nor OpenCode found; use --target claude|opencode|both")
    sc.kit.mkdir(parents=True, exist_ok=True)
    if src.resolve() != sc.kit.resolve():
        for d in KIT_DIRS:
            shutil.rmtree(sc.kit / d, ignore_errors=True)
            shutil.copytree(src / d, sc.kit / d, ignore=shutil.ignore_patterns("__pycache__"))
    cli = sc.kit / "cli" / "forge.py"
    cli.chmod(cli.stat().st_mode | stat.S_IEXEC)
    sc.bin.mkdir(parents=True, exist_ok=True)
    if WIN:
        shim = sc.bin / "forge.cmd"
        py = "python" if sc.kind == "local" else f'"{sys.executable}"'
        target_cli = r"%~dp0..\kit\cli\forge.py" if sc.kind == "local" else str(cli)
        shim.write_text(f'@echo off\r\n{py} "{target_cli}" %*\r\n')
        created.append(str(shim))
    elif sc.kind == "local":
        shim = sc.bin / "forge"
        shim.write_text('#!/usr/bin/env sh\nexec python3 "$(dirname "$0")/../kit/cli/forge.py" "$@"\n')
        shim.chmod(shim.stat().st_mode | stat.S_IEXEC)
        created.append(str(shim))
    else:
        link = sc.bin / "forge"
        if link.is_symlink() or link.exists():
            link.unlink()
        link.symlink_to(cli); created.append(str(link))
        if str(sc.bin) not in os.environ.get("PATH", ""):
            log(f"add {sc.bin} to your PATH to run `forge`")
    skills = [p for p in (sc.kit / "skills").iterdir() if p.is_dir()]
    agents = sorted((sc.kit / "agents").glob("*.md"))
    settings_created = None
    for t in targets:
        base = sc.claude if t == "claude" else sc.opencode
        for s in skills:
            dst = base / "skills" / s.name
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(s, dst, ignore=shutil.ignore_patterns("__pycache__"))
            created.append(str(dst)); installed += [str(p) for p in dst.rglob("*") if p.is_file()]
        (base / "agents").mkdir(parents=True, exist_ok=True)
        for a in agents:
            dst = base / "agents" / a.name
            dst.write_text(convert_agent(a.stem, a.read_text(encoding="utf-8"), t), encoding="utf-8")
            created.append(str(dst)); installed.append(str(dst))
        if t == "claude":
            settings_created = edit_claude_settings(sc, True)
            log("claude: skills, agents and hooks installed (hooks merged into settings.json)")
        else:
            (base / "plugins").mkdir(parents=True, exist_ok=True)
            old = base / "plugin" / "forge.ts"          # location and file of earlier installs
            if old.exists():
                old.unlink()
            plug = base / "plugins" / "forge.js"
            txt = (sc.kit / "hooks" / "opencode-forge.js").read_text(encoding="utf-8")
            py = sys.executable if sc.kind == "global" else ("python" if WIN else "python3")
            cli_path = str(sc.kit / "cli" / "forge.py") if sc.kind == "global" else ".forge/kit/cli/forge.py"
            txt = txt.replace('const PYTHON = "python3"', "const PYTHON = " + json.dumps(py))
            txt = txt.replace('const CLI = ".forge/kit/cli/forge.py"', "const CLI = " + json.dumps(cli_path))
            plug.write_text(txt, encoding="utf-8")
            created.append(str(plug)); installed.append(str(plug))
            log("opencode: skills, agents and plugin installed")
    files = {}
    for d in KIT_DIRS:
        for p in sorted((sc.kit / d).rglob("*")):
            if p.is_file() and "__pycache__" not in p.parts:
                files[str(p.relative_to(sc.kit)).replace("\\", "/")] = hashlib.sha256(p.read_bytes()).hexdigest()
    inst = {sc.rel(Path(f)): h for f, h in hashes_of(installed).items()}
    (sc.kit / "kit.sha256").write_text(json.dumps({"files": files, "installed": {
        "relative_to": "project" if sc.kind == "local" else "absolute", "files": inst}}, indent=1), encoding="utf-8")
    sc.manifest.write_text(json.dumps({"scope": sc.kind, "targets": targets, "settings_created": bool(settings_created),
                                       "created": [sc.rel(Path(c)) for c in created]}, indent=2), encoding="utf-8")
    if sc.kind == "local":
        log("project install done. Commit .forge/kit, .claude and .opencode to share it, or add them to .gitignore to keep it personal.")
        log("in this project, `forge` means .forge/bin/forge (add .forge/bin to PATH to type `forge`)")
        g = HOME / ".claude" / "settings.json"
        if g.exists() and "forge_hook" in g.read_text(encoding="utf-8"):
            log("warning: a global Forge install also has hooks; remove one of the two or hooks run twice")
    log("done. Open the project and run: forge init --name <Name> --lang <code>")


def uninstall(sc):
    if sc.manifest.exists():
        m = json.loads(sc.manifest.read_text(encoding="utf-8"))
        for c in m["created"]:
            p = sc.absolute(c)
            if p.is_dir():
                shutil.rmtree(p, ignore_errors=True)
            elif p.exists() or p.is_symlink():
                p.unlink()
        if "claude" in m["targets"] and sc.settings.exists():
            edit_claude_settings(sc, False)
        for d in [sc.claude / "skills", sc.claude / "agents", sc.opencode / "skills", sc.opencode / "agents",
                  sc.opencode / "plugin", sc.opencode / "plugins", sc.bin]:
            if d.is_dir() and not any(d.iterdir()):
                d.rmdir()
        for d in (sc.claude, sc.opencode):
            if sc.kind == "local" and d.is_dir() and not any(d.iterdir()):
                d.rmdir()
    shutil.rmtree(sc.kit, ignore_errors=True)
    log(f"{sc.kind} install removed" + (" (the project's .forge state is untouched)" if sc.kind == "local" else ""))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=str(Path(__file__).resolve().parent.parent))
    ap.add_argument("--scope", choices=["global", "local"])
    ap.add_argument("--project", default=".")
    ap.add_argument("--target", default="auto", choices=["auto", "claude", "opencode", "both"])
    ap.add_argument("--uninstall", action="store_true")
    a = ap.parse_args()
    if sys.version_info < (3, 9):
        sys.exit("forge-install: Python 3.9 or newer is required")
    project = Path(a.project).resolve()
    if a.uninstall:
        have = [k for k, s in (("global", Scope("global")), ("local", Scope("local", project))) if s.manifest.exists()]
        kind = a.scope or (have[0] if len(have) == 1 else None)
        if kind is None:
            sys.exit("forge-install: " + ("nothing is installed here" if not have else "both scopes are installed; pass --scope global or --scope local"))
        uninstall(Scope(kind, project if kind == "local" else None))
    else:
        kind = a.scope or prompt_scope()
        if kind == "local" and not project.is_dir():
            sys.exit(f"forge-install: project directory {project} does not exist")
        install(Scope(kind, project if kind == "local" else None), Path(a.src), a.target)
