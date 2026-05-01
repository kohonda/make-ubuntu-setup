#!/usr/bin/env bash
# Shared helpers for installer scripts. Source this file with `source`.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

if [ -t 1 ]; then
  _C_RESET="$(printf '\033[0m')"
  _C_INFO="$(printf '\033[1;34m')"
  _C_WARN="$(printf '\033[1;33m')"
  _C_ERR="$(printf '\033[1;31m')"
else
  _C_RESET=""; _C_INFO=""; _C_WARN=""; _C_ERR=""
fi

log_info() { printf '%s[INFO]%s %s\n' "$_C_INFO" "$_C_RESET" "$*"; }
log_warn() { printf '%s[WARN]%s %s\n' "$_C_WARN" "$_C_RESET" "$*" >&2; }
log_err()  { printf '%s[ERR ]%s %s\n' "$_C_ERR"  "$_C_RESET" "$*" >&2; }

is_installed() {
  command -v "$1" >/dev/null 2>&1
}

dpkg_installed() {
  dpkg -s "$1" >/dev/null 2>&1
}

apt_install() {
  local missing=()
  local pkg
  for pkg in "$@"; do
    if dpkg_installed "$pkg"; then
      log_info "apt: $pkg already installed, skipping"
    else
      missing+=("$pkg")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    log_info "apt: installing ${missing[*]}"
    sudo apt-get install -y "${missing[@]}"
  fi
}
