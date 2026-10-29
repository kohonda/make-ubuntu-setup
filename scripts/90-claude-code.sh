#!/usr/bin/env bash
# Claude Code via the official native installer.
# Reference: https://docs.claude.com/en/docs/claude-code/setup

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

if is_installed claude || [ -x "${HOME}/.local/bin/claude" ]; then
  log_info "claude already installed, skipping"
  exit 0
fi

log_info "Installing Claude Code"
curl -fsSL https://claude.ai/install.sh | bash
log_warn "claude installed to \$HOME/.local/bin. Open a new shell or 'source ~/.bashrc' to use it."
