#!/usr/bin/env bash
# uv (Python package/version manager) via official installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

if is_installed uv || [ -x "${HOME}/.local/bin/uv" ]; then
  log_info "uv already installed, skipping"
  exit 0
fi

log_info "Installing uv"
curl -LsSf https://astral.sh/uv/install.sh | sh
log_warn "uv installed to \$HOME/.local/bin. Open a new shell or 'source ~/.bashrc' to use it."
