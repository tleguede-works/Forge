#!/usr/bin/env bash
# Installer: global and local scopes, integrity of installed copies, idempotence, clean uninstall that keeps project state.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ok()   { "$@" >/dev/null 2>&1 || { echo "FAIL (expected success): $*"; exit 1; }; }
fail() { "$@" >/dev/null 2>&1 && { echo "FAIL (expected refusal): $*"; exit 1; }; true; }
has()  { grep -q "$1" "$2" 2>/dev/null || { echo "FAIL: '$1' not found in $2"; exit 1; }; }
here() { [ -e "$1" ] || { echo "FAIL: missing $1"; exit 1; }; }
gone() { [ ! -e "$1" ] || { echo "FAIL: still present $1"; exit 1; }; }

echo "--- global scope (no terminal, no --scope: defaults to global) ---"
FH=$(mktemp -d); mkdir -p $FH/.claude $FH/.config/opencode
echo '{"theme":"dark","hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo keep"}]}]}}' > $FH/.claude/settings.json
ok env HOME=$FH FORGE_SRC=$ROOT sh $ROOT/install.sh
ok env HOME=$FH FORGE_SRC=$ROOT sh $ROOT/install.sh          # twice: idempotent
K="python3 $FH/.forge/cli/forge.py"
here $FH/.forge/cli/forge.py; here $FH/.claude/skills/forge-compliance/SKILL.md; here $FH/.config/opencode/plugins/forge.js
has 'const CLI = "'$FH'/.forge/cli/forge.py"' $FH/.config/opencode/plugins/forge.js
python3 - "$FH" <<'P'
import json,sys
c=json.load(open(sys.argv[1]+"/.claude/settings.json"))
n=sum("forge_hook" in h["command"] for g in c["hooks"].values() for x in g for h in x["hooks"])
assert n==4 and c["theme"]=="dark" and "Stop" in c["hooks"], (n,c)
P
ok $K kit verify
echo "# tampered" >> $FH/.claude/skills/forge/SKILL.md; fail $K kit verify          # an installed copy was edited
ok env HOME=$FH FORGE_SRC=$ROOT sh $ROOT/install.sh; ok $K kit verify               # reinstall restores it
echo "# tampered" >> $FH/.forge/skills/forge/SKILL.md; fail $K kit verify          # the kit copy was edited
cd $(mktemp -d); $K init --name K >/dev/null 2>&1
$K status 2>&1 | grep -q "KIT MODIFIED" || { echo "FAIL: status does not report the modified kit"; exit 1; }
$K phase start bootstrap >/dev/null 2>&1
$K template contract | sed "s/<fill>/x text/" > .forge/contract.md; $K template brief | sed "s/<fill>/x text/" > .forge/brief.md
$K register contract .forge/contract.md >/dev/null; $K register brief .forge/brief.md >/dev/null
mkdir -p .forge/reviews
for n in contract brief; do for ag in qa redteam; do $K review begin $n --agent $ag >/dev/null; echo '{"findings":[]}' > .forge/reviews/$n.$ag.json; $K review record $n --agent $ag --report .forge/reviews/$n.$ag.json >/dev/null; done; done
fail $K gate approve --evidence "approved"                                           # a modified kit cannot approve
ok env HOME=$FH python3 $FH/.forge/scripts/install.py --uninstall
gone $FH/.forge; gone $FH/.claude/skills/forge
python3 -c "import json,sys;c=json.load(open('$FH/.claude/settings.json'));assert c['theme']=='dark' and list(c['hooks'])==['Stop'],c"

echo "--- local scope ---"
FH2=$(mktemp -d); P=$(mktemp -d); mkdir -p $P/.claude $P/.opencode
echo '{"permissions":{"allow":["Bash(ls)"]}}' > $P/.claude/settings.json
ok env HOME=$FH2 FORGE_SRC=$ROOT sh $ROOT/install.sh --scope local --project $P
ok env HOME=$FH2 FORGE_SRC=$ROOT sh $ROOT/install.sh --scope local --project $P          # twice
gone $FH2/.forge; gone $FH2/.claude                                                       # nothing leaks into the home folder
here $P/.forge/kit/cli/forge.py; here $P/.forge/bin/forge; here $P/.claude/skills/forge/SKILL.md; here $P/.claude/agents/forge.md
here $P/.opencode/skills/forge-rules/SKILL.md; here $P/.opencode/agents/forge-qa.md; here $P/.opencode/plugins/forge.js
has 'CLAUDE_PROJECT_DIR' $P/.claude/settings.json; has '"Bash(ls)"' $P/.claude/settings.json
has 'const CLI = ".forge/kit/cli/forge.py"' $P/.opencode/plugins/forge.js
python3 - "$P" <<'P'
import json,sys
c=json.load(open(sys.argv[1]+"/.claude/settings.json"))
n=sum("forge_hook" in h["command"] for g in c["hooks"].values() for x in g for h in x["hooks"])
assert n==4 and "$HOME" not in json.dumps(c) and "/tmp" not in json.dumps(c["hooks"]), c   # portable: no machine path
P
cd $P
ok env HOME=$FH2 .forge/bin/forge init --name L --lang en
has '\.forge/bin/forge' AGENTS.md                                                         # agents are told what `forge` means here
ok .forge/bin/forge kit verify
echo '{"cwd":"'$P'"}' | python3 .forge/kit/hooks/forge_hook.py session-start | grep -q "Forge memory" || { echo "FAIL: local hook does not run"; exit 1; }
echo "# tampered" >> .claude/skills/forge/SKILL.md; fail .forge/bin/forge kit verify
ok env HOME=$FH2 FORGE_SRC=$ROOT sh $ROOT/install.sh --scope local --project $P; ok .forge/bin/forge kit verify
ok env HOME=$FH2 python3 .forge/kit/scripts/install.py --uninstall --scope local --project $P
gone .forge/kit; gone .forge/bin; gone .claude/skills/forge; gone .opencode/plugins/forge.js; here .forge/state.json; here AGENTS.md
python3 -c "import json;c=json.load(open('.claude/settings.json'));assert c=={'permissions':{'allow':['Bash(ls)']}},c"

echo "--- both scopes present: the scope must be named ---"
FH3=$(mktemp -d); P3=$(mktemp -d); mkdir -p $FH3/.claude $P3/.claude
ok env HOME=$FH3 FORGE_SRC=$ROOT sh $ROOT/install.sh --scope global
ok env HOME=$FH3 FORGE_SRC=$ROOT sh $ROOT/install.sh --scope local --project $P3
fail env HOME=$FH3 python3 $ROOT/scripts/install.py --uninstall --project $P3
ok env HOME=$FH3 python3 $ROOT/scripts/install.py --uninstall --scope local --project $P3
here $FH3/.forge/cli/forge.py; gone $P3/.forge/kit
ok env HOME=$FH3 python3 $ROOT/scripts/install.py --uninstall --scope global
gone $FH3/.forge
echo "--- interactive choice on a terminal ---"
ask() { python3 - "$ROOT" "$1" "$2" "$3" <<'PY'
import os,pty,sys,select,time
root,proj,home,ans=sys.argv[1:5]
pid,fd=pty.fork()
if pid==0:
    os.environ["HOME"]=home; os.chdir(proj)
    os.execvp("python3",["python3",root+"/scripts/install.py","--src",root])
buf=b""; sent=False; end=time.time()+90
while time.time()<end:
    r,_,_=select.select([fd],[],[],1)
    if r:
        try: d=os.read(fd,4096)
        except OSError: break
        if not d: break
        buf+=d
        if b"Choice" in buf and not sent:
            os.write(fd,(ans+"\n").encode()); sent=True
_,status=os.waitpid(pid,0)
sys.exit(0 if os.WIFEXITED(status) and os.WEXITSTATUS(status)==0 and sent else 1)
PY
}
P4=$(mktemp -d); H4=$(mktemp -d); mkdir -p $P4/.claude $H4/.claude
ok ask $P4 $H4 2;  here $P4/.forge/kit/cli/forge.py; gone $H4/.forge                     # answer 2: local
P5=$(mktemp -d); H5=$(mktemp -d); mkdir -p $P5/.claude $H5/.claude
ok ask $P5 $H5 "";  here $H5/.forge/cli/forge.py; gone $P5/.forge                        # empty answer: global (the default)
echo "INSTALL PASS"
