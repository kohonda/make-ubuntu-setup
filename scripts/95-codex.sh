#!/usr/bin/env bash
# Codex CLI via the official standalone installer (no Node.js dependency).
# Reference: https://github.com/openai/codex#installing-and-running-codex-cli

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

if is_installed codex || [ -x "${HOME}/.local/bin/codex" ]; then
  log_info "codex already installed, skipping"
  exit 0
fi

log_info "Installing Codex CLI"
curl -fsSL https://chatgpt.com/codex/install.sh | sh
log_warn "codex installed to \$HOME/.local/bin. Open a new shell or 'source ~/.bashrc' to use it."
