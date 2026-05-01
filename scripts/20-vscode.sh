#!/usr/bin/env bash
# Visual Studio Code via Microsoft apt repository.
# Reference: https://code.visualstudio.com/docs/setup/linux

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

if is_installed code; then
  log_info "code already installed, skipping"
  exit 0
fi

KEYRING=/usr/share/keyrings/packages.microsoft.gpg
LIST=/etc/apt/sources.list.d/vscode.list

apt_install wget gpg apt-transport-https

if [ ! -f "$KEYRING" ]; then
  log_info "Adding Microsoft signing key"
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | sudo gpg --dearmor -o "$KEYRING"
fi

if [ ! -f "$LIST" ]; then
  log_info "Adding VSCode apt source"
  echo "deb [arch=amd64,arm64,armhf signed-by=${KEYRING}] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee "$LIST" >/dev/null
fi

sudo apt-get update
apt_install code
