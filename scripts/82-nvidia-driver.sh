#!/usr/bin/env bash
# NVIDIA driver chosen by ubuntu-drivers, on machines with an NVIDIA GPU only.
# A driver that is already installed is never upgraded or replaced.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

DRIVER_PACKAGE_PATTERN="nvidia-driver-*"

# The pattern also matches packages dpkg only knows by name (nvidia-driver-binary
# as not-installed) and removed ones (rc), so compare the full status string.
has_driver_package() {
  local statuses
  statuses="$(dpkg-query -W -f='${Status}\n' "$DRIVER_PACKAGE_PATTERN" 2>/dev/null)" || return 1
  grep -qxF "$DPKG_STATUS_INSTALLED" <<<"$statuses"
}

if ! has_nvidia_gpu; then
  log_info "No NVIDIA GPU found, skipping"
  exit 0
fi

if nvidia_smi_works; then
  log_info "nvidia-smi works, driver already installed, skipping"
  exit 0
fi

if has_driver_package; then
  log_warn "An NVIDIA driver is installed but nvidia-smi does not work. Reboot to activate it. Skipping"
  exit 0
fi

apt_install ubuntu-drivers-common

log_info "Installing the NVIDIA driver recommended by ubuntu-drivers"
# sudo drops DEBIAN_FRONTEND, and on a Secure Boot machine DKMS reaches a debconf
# prompt for a MOK password (update-secureboot-policy --enroll-key).
# The exit code says nothing: `ubuntu-drivers install` discards command_install()'s
# result, so success is judged from dpkg below, and a failure must not stop the other tools.
sudo DEBIAN_FRONTEND=noninteractive ubuntu-drivers install \
  || log_warn "ubuntu-drivers install exited with an error"

if ! has_driver_package; then
  log_warn "ubuntu-drivers did not install an NVIDIA driver; install one by hand. Continuing"
  exit 0
fi

log_warn "NVIDIA driver installed. Reboot to activate it."
