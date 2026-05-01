#!/usr/bin/env bash
# Fcitx5 + Mozc Japanese input method.
# Henkan (変換) key activates Mozc; Muhenkan (無変換) deactivates it.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

REPO_ROOT="${REPO_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
SRC_CONFIG="${REPO_ROOT}/config/fcitx5"

apt_install fcitx5 fcitx5-mozc fcitx5-config-qt im-config

# Set fcitx5 as the default input-method framework for the current user.
log_info "Setting fcitx5 as default input method (im-config -n fcitx5)"
im-config -n fcitx5 >/dev/null

# System-wide IM environment variables (works for X11 and most Wayland setups).
ENV_FILE=/etc/environment.d/99-fcitx5.conf
if [ ! -f "$ENV_FILE" ]; then
  log_info "Writing IM environment variables to $ENV_FILE"
  sudo install -d -m 0755 /etc/environment.d
  sudo tee "$ENV_FILE" >/dev/null <<'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF
else
  log_info "$ENV_FILE already exists, skipping"
fi

# Per-user fcitx5 config. Skip when files already exist to respect customizations.
USER_CONF_DIR="${HOME}/.config/fcitx5"
mkdir -p "${USER_CONF_DIR}/conf"

PROFILE_DST="${USER_CONF_DIR}/profile"
if [ -e "$PROFILE_DST" ]; then
  log_info "$PROFILE_DST already exists, skipping"
else
  log_info "Installing $PROFILE_DST"
  install -m 0644 "${SRC_CONFIG}/profile" "$PROFILE_DST"
fi

# Global hotkeys (Henkan / Muhenkan) live in ~/.config/fcitx5/config, not conf/.
GLOBAL_DST="${USER_CONF_DIR}/config"
if [ -e "$GLOBAL_DST" ]; then
  log_info "$GLOBAL_DST already exists, skipping"
else
  log_info "Installing $GLOBAL_DST"
  install -m 0644 "${SRC_CONFIG}/conf/default.conf" "$GLOBAL_DST"
fi

log_warn "Log out and log back in to activate Fcitx5."
log_warn "After login: 変換 key turns Mozc ON, 無変換 key turns it OFF."
