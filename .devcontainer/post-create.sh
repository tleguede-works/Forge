#!/usr/bin/env bash
# Runs on every codespace creation, via .devcontainer/devcontainer.json.
#
# Idempotent: creating a codespace, or running this by hand, lands on the same state.
# Nothing here reads or writes a secret -- provider keys are supplied by the user.
set -euo pipefail

step() {
    printf '\n\033[1;34m==> %s\033[0m\n' "$1"
}

step "OpenCode v2 (latest release)"
# The official v2 installer, not the devcontainers-extra/opencode feature: that feature
# resolves "latest" on the anomalyco GitHub releases, and v1 and v2 publish there side by
# side under the same `opencode` command. This endpoint is v2-scoped, so "latest" is
# unambiguous. Deliberately not pinned to a version: a codespace should never start on an
# older OpenCode than the one the work was last done with.
curl -fsSL https://opencode.ai/v2/install | bash

# The installer only appends its PATH line to ~/.bashrc. A codespace also starts shells
# that never source it -- VS Code tasks, extensions, the TUI launched from the command
# palette -- so the binary is exposed in /usr/local/bin, already on PATH for all of them.
sudo ln -sf "$HOME/.opencode/bin/opencode" /usr/local/bin/opencode
opencode --version

step "Ready"
printf 'opencode  %s\n' "$(command -v opencode)"
printf '\nIf opencode reports no provider, run /connect -- or expose the key as a\n'
printf 'Codespaces secret, which is the only version that survives a codespace restart.\n'
