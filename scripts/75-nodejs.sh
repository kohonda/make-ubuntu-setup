#!/usr/bin/env bash
# Node.js (current LTS) via the NodeSource apt repository.
# Reference: https://github.com/nodesource/distributions

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

NODESOURCE_SETUP_URL=https://deb.nodesource.com/setup_lts.x

# A node already on PATH (Ubuntu's package, nvm, ...) is the user's choice; keep it.
if is_installed node; then
  log_info "node already installed ($(node --version)), skipping"
  exit 0
fi

log_info "Adding NodeSource LTS apt repository"
curl -fsSL "$NODESOURCE_SETUP_URL" | sudo -E bash -
apt_install nodejs
