#!/usr/bin/env bash
# Fcitx5 + Mozc Japanese input method.
# Henkan (変換) always switches to Mozc; Muhenkan (無変換) always switches to the
# plain keyboard. Neither key toggles.
# Keyboard layout: FCITX5_LAYOUT (default: jp). For a US keyboard run
#   FCITX5_LAYOUT=us bash install.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

REPO_ROOT="${REPO_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
SRC_CONFIG="${REPO_ROOT}/config/fcitx5"
LAYOUT="${FCITX5_LAYOUT:-jp}"
LAYOUT_PATTERN='^[a-z]+$'
USER_CONF_DIR="${HOME}/.config/fcitx5"
ENV_FILE=/etc/environment.d/99-fcitx5.conf
INPUT_SOURCES_SCHEMA=org.gnome.desktop.input-sources
FCITX5_EXIT_TIMEOUT_SECONDS=10
QT6_FRONTEND=fcitx5-frontend-qt6

# The frontends are only Recommends of fcitx5, so --no-install-recommends drops them.
install_fcitx5_packages() {
  apt_install fcitx5 fcitx5-mozc fcitx5-config-qt im-config \
    fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5
  # Ubuntu 22.04 does not ship the Qt6 frontend.
  if apt-cache show "$QT6_FRONTEND" >/dev/null 2>&1; then
    apt_install "$QT6_FRONTEND"
  fi
}

# fcitx5 writes its in-memory config back on exit, which would overwrite ours.
stop_fcitx5() {
  pkill -x fcitx5 || return 0
  local waited=0
  while pgrep -x fcitx5 >/dev/null && [ "$waited" -lt "$FCITX5_EXIT_TIMEOUT_SECONDS" ]; do
    sleep 1
    waited=$((waited + 1))
  done
}

# Writes $1 to $2, keeping a differing previous file as $2.bak. An identical
# file is left alone so a re-run does not replace the backup with our own output.
install_with_backup() {
  local src="$1"
  local dst="$2"
  if cmp -s "$src" "$dst"; then
    log_info "$dst is up to date"
    return 0
  fi
  if [ -e "$dst" ]; then
    log_info "Backing up $dst to ${dst}.bak"
    cp -p "$dst" "${dst}.bak"
  fi
  log_info "Writing $dst"
  install -m 0644 "$src" "$dst"
}

# Same as install_with_backup, for a root-owned destination.
sudo_install_with_backup() {
  local src="$1"
  local dst="$2"
  if cmp -s "$src" "$dst"; then
    log_info "$dst is up to date"
    return 0
  fi
  if [ -e "$dst" ]; then
    log_info "Backing up $dst to ${dst}.bak"
    sudo cp -p "$dst" "${dst}.bak"
  fi
  log_info "Writing $dst"
  sudo install -D -m 0644 "$src" "$dst"
}

write_im_environment() (
  local generated
  generated="$(mktemp)"
  trap 'rm -f "$generated"' EXIT
  printf '%s\n' GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx >"$generated"
  sudo_install_with_backup "$generated" "$ENV_FILE"
)

write_fcitx5_profile() (
  local generated
  generated="$(mktemp)"
  trap 'rm -f "$generated"' EXIT
  sed "s/@LAYOUT@/${LAYOUT}/g" "${SRC_CONFIG}/profile.template" >"$generated"
  install_with_backup "$generated" "${USER_CONF_DIR}/profile"
)

# GNOME starts ibus for any ibus engine left in its input sources, and two IMEs
# then fight over the keyboard. ibus itself stays: removing it can take
# ubuntu-desktop with it.
reset_gnome_input_sources() {
  if ! is_installed gsettings || ! gsettings list-schemas 2>/dev/null | grep -qx "$INPUT_SOURCES_SCHEMA"; then
    log_info "GNOME input-sources not available, skipping"
    return 0
  fi
  log_info "Setting GNOME input sources to xkb:${LAYOUT}"
  if ! gsettings set "$INPUT_SOURCES_SCHEMA" sources "[('xkb', '${LAYOUT}')]"; then
    log_warn "gsettings failed (no desktop session?); re-run this script after logging in"
  fi
}

if ! [[ "$LAYOUT" =~ $LAYOUT_PATTERN ]]; then
  log_err "FCITX5_LAYOUT must be an XKB layout name such as jp or us (got: ${LAYOUT})"
  exit 2
fi

install_fcitx5_packages

log_info "Setting fcitx5 as default input method (im-config -n fcitx5)"
im-config -n fcitx5 >/dev/null

stop_fcitx5
mkdir -p "$USER_CONF_DIR"
write_im_environment
write_fcitx5_profile
install_with_backup "${SRC_CONFIG}/config" "${USER_CONF_DIR}/config"
reset_gnome_input_sources

log_warn "Log out and log back in to activate Fcitx5."
log_warn "After login: 変換 key switches to Mozc, 無変換 key switches to direct input."
