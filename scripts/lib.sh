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

DPKG_STATUS_INSTALLED="install ok installed"

PCI_DEVICES_DIR="${PCI_DEVICES_DIR:-/sys/bus/pci/devices}"
NVIDIA_PCI_VENDOR_ID="0x10de"
# Display controllers only: an NVIDIA GPU's audio function has class 0x0403xx.
PCI_CLASS_DISPLAY_PREFIX="0x03"

is_installed() {
  command -v "$1" >/dev/null 2>&1
}

# `dpkg -s` also succeeds for packages in the `rc` state (removed, config files
# left behind), so check the full status string instead.
dpkg_installed() {
  local status
  status="$(dpkg-query -W -f='${Status}' "$1" 2>/dev/null)" || return 1
  [ "$status" = "$DPKG_STATUS_INSTALLED" ]
}

# Reads sysfs so that it works before pciutils and the driver are installed.
has_nvidia_gpu() {
  local device
  for device in "$PCI_DEVICES_DIR"/*; do
    [ -r "$device/vendor" ] || continue
    [ -r "$device/class" ] || continue
    [ "$(<"$device/vendor")" = "$NVIDIA_PCI_VENDOR_ID" ] || continue
    case "$(<"$device/class")" in
      "$PCI_CLASS_DISPLAY_PREFIX"*) return 0 ;;
    esac
  done
  return 1
}

nvidia_smi_works() {
  nvidia-smi >/dev/null 2>&1
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

# Runs in a subshell so the EXIT trap cleans up the download on success and on failure.
install_deb_from_url() (
  local url="$1"
  local workdir
  workdir="$(mktemp -d)"
  trap 'rm -rf "$workdir"' EXIT
  # apt drops privileges to the _apt user to read local .deb files.
  chmod 0755 "$workdir"
  local deb="${workdir}/package.deb"
  log_info "Downloading $url"
  curl -fsSL -o "$deb" "$url"
  chmod 0644 "$deb"
  sudo apt-get install -y "$deb"
)

# Deletes a file an older version of this installer wrote, but only when it is
# byte-identical to what that version wrote: a file the user or a package
# rewrote since is kept.
remove_if_identical() {
  local target="$1"
  local reference="$2"
  [ -e "$target" ] || return 0
  if ! cmp -s "$target" "$reference"; then
    log_warn "$target differs from what an older installer wrote; leaving it in place"
    return 0
  fi
  log_info "Removing legacy $target"
  sudo rm -f "$target"
}

# Same as remove_if_identical, for a one-line file written with `echo ... | tee`.
remove_if_single_line() (
  local target="$1"
  local line="$2"
  local reference
  reference="$(mktemp)"
  trap 'rm -f "$reference"' EXIT
  printf '%s\n' "$line" >"$reference"
  remove_if_identical "$target" "$reference"
)
