#!/usr/bin/env bash
# Google Chrome via official apt repository.
# Reference: https://support.google.com/chrome/answer/95346

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

if is_installed google-chrome || is_installed google-chrome-stable; then
  log_info "google-chrome already installed, skipping"
  exit 0
fi

KEYRING=/usr/share/keyrings/google-chrome.gpg
LIST=/etc/apt/sources.list.d/google-chrome.list

if [ ! -f "$KEYRING" ]; then
  log_info "Adding Google signing key"
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
    | sudo gpg --dearmor -o "$KEYRING"
fi

if [ ! -f "$LIST" ]; then
  log_info "Adding Google Chrome apt source"
  echo "deb [arch=amd64 signed-by=${KEYRING}] https://dl.google.com/linux/chrome/deb/ stable main" \
    | sudo tee "$LIST" >/dev/null
fi

sudo apt-get update
apt_install google-chrome-stable
