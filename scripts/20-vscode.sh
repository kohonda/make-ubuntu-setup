#!/usr/bin/env bash
# Visual Studio Code via the official .deb. The package registers its own apt
# source (vscode.sources) for updates, so this script writes none.
# Reference: https://code.visualstudio.com/docs/setup/linux

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

VSCODE_DEB_URL_BASE=https://update.code.visualstudio.com/latest
MICROSOFT_KEY_URL=https://packages.microsoft.com/keys/microsoft.asc
LEGACY_KEYRING=/usr/share/keyrings/packages.microsoft.gpg
LEGACY_LIST=/etc/apt/sources.list.d/vscode.list
LEGACY_LIST_LINE="deb [arch=amd64,arm64,armhf signed-by=${LEGACY_KEYRING}] https://packages.microsoft.com/repos/code stable main"

vscode_platform() {
  case "$(dpkg --print-architecture)" in
    amd64) echo x64 ;;
    arm64) echo arm64 ;;
    *) return 1 ;;
  esac
}

# Rebuilds the keyring the old script produced (dearmored microsoft.asc) so the
# installed one is deleted only when it is exactly that file.
remove_legacy_keyring() (
  [ -e "$LEGACY_KEYRING" ] || exit 0
  local reference
  reference="$(mktemp)"
  trap 'rm -f "$reference"' EXIT
  curl -fsSL "$MICROSOFT_KEY_URL" | gpg --dearmor >"$reference"
  remove_if_identical "$LEGACY_KEYRING" "$reference"
)

# The old list points at the same URI as the package's vscode.sources with a
# different Signed-By, which makes every apt command fail with "Conflicting values".
remove_if_single_line "$LEGACY_LIST" "$LEGACY_LIST_LINE"
if [ ! -e "$LEGACY_LIST" ]; then
  remove_legacy_keyring
fi

if dpkg_installed code; then
  log_info "code already installed, skipping"
  exit 0
fi

if ! platform="$(vscode_platform)"; then
  log_warn "VSCode .deb is not published for $(dpkg --print-architecture), skipping"
  exit 0
fi

# Answer the package's own question up front so it adds its apt source non-interactively.
echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
install_deb_from_url "${VSCODE_DEB_URL_BASE}/linux-deb-${platform}/stable"
