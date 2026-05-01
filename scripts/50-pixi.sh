#!/usr/bin/env bash
# pixi (cross-platform package manager for conda-forge) via official installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

if is_installed pixi || [ -x "${HOME}/.pixi/bin/pixi" ]; then
  log_info "pixi already installed, skipping"
  exit 0
fi

log_info "Installing pixi"
curl -fsSL https://pixi.sh/install.sh | bash
log_warn "pixi installed to \$HOME/.pixi/bin. Open a new shell or 'source ~/.bashrc' to use it."
