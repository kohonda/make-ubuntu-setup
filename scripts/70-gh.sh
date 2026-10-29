#!/usr/bin/env bash
# GitHub CLI (gh) via the official apt repository.
# Reference: https://github.com/cli/cli/blob/trunk/docs/install_linux.md

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

KEYRING=/etc/apt/keyrings/githubcli-archive-keyring.gpg
KEYRING_URL=https://cli.github.com/packages/githubcli-archive-keyring.gpg
LIST=/etc/apt/sources.list.d/github-cli.list

# An existing gh may come from a list with another Signed-By path; adding ours
# next to it would make apt fail with "Conflicting values".
if is_installed gh; then
  log_info "gh already installed, skipping"
  exit 0
fi

sudo install -d -m 0755 /etc/apt/keyrings
if [ ! -f "$KEYRING" ]; then
  log_info "Adding GitHub CLI signing key"
  curl -fsSL "$KEYRING_URL" | sudo tee "$KEYRING" >/dev/null
  sudo chmod go+r "$KEYRING"
fi

if [ ! -f "$LIST" ]; then
  log_info "Adding GitHub CLI apt source"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=${KEYRING}] https://cli.github.com/packages stable main" \
    | sudo tee "$LIST" >/dev/null
fi

sudo apt-get update
apt_install gh
