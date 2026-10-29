#!/usr/bin/env bash
# Google Chrome via the official .deb. The package registers its own apt source
# (google-chrome.sources) for updates, so this script writes none.
# Reference: https://support.google.com/chrome/answer/95346

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

CHROME_DEB_URL=https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
CHROME_ARCH=amd64
LEGACY_LIST=/etc/apt/sources.list.d/google-chrome.list
LEGACY_LIST_LINE="deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main"

if [ "$(dpkg --print-architecture)" != "$CHROME_ARCH" ]; then
  log_warn "Google Chrome is only published for ${CHROME_ARCH}, skipping"
  exit 0
fi

# The old version of this script wrote this list; together with the package's
# own google-chrome.sources it registered the repository twice.
remove_if_single_line "$LEGACY_LIST" "$LEGACY_LIST_LINE"

if dpkg_installed google-chrome-stable; then
  log_info "google-chrome-stable already installed, skipping"
  exit 0
fi

install_deb_from_url "$CHROME_DEB_URL"
