#!/usr/bin/env sh
# One-line install:  curl -fsSL https://raw.githubusercontent.com/tleguede-works/Forge/main/install.sh | sh
# Options are passed through, e.g.:  ... | sh -s -- --scope local     or     --scope global --target claude     or     --uninstall
# Without --scope the installer asks on the terminal; with no terminal it installs globally.
set -eu
REPO="${FORGE_REPO:-tleguede-works/Forge}"
REF="${FORGE_REF:-main}"
command -v python3 >/dev/null 2>&1 || { echo "forge-install: python3 is required" >&2; exit 1; }
python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))' || { echo "forge-install: Python 3.9+ required" >&2; exit 1; }
if [ -n "${FORGE_SRC:-}" ]; then
  SRC="$FORGE_SRC"
else
  command -v curl >/dev/null 2>&1 || { echo "forge-install: curl is required" >&2; exit 1; }
  TMP="$(mktemp -d)"
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/$REF.tar.gz" | tar xz -C "$TMP"
  SRC="$(ls -d "$TMP"/*/ | head -n 1)"
fi
python3 "$SRC/scripts/install.py" --src "$SRC" "$@"
