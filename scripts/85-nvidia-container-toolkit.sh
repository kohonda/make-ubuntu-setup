#!/usr/bin/env bash
# NVIDIA Container Toolkit, on machines with an NVIDIA GPU only.
# The driver comes from scripts/82-nvidia-driver.sh. Neither installing the toolkit
# nor configuring docker needs it loaded, so this also runs before the first reboot.
# Reference: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

KEYRING=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
KEYRING_URL=https://nvidia.github.io/libnvidia-container/gpgkey
LIST=/etc/apt/sources.list.d/nvidia-container-toolkit.list
LIST_URL=https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list

if ! has_nvidia_gpu; then
  log_warn "No NVIDIA GPU found, skipping"
  exit 0
fi

if ! is_installed docker; then
  log_warn "docker is not installed; run scripts/80-docker.sh first. Skipping"
  exit 0
fi

if dpkg_installed nvidia-container-toolkit; then
  log_info "nvidia-container-toolkit already installed, skipping"
  exit 0
fi

if [ ! -f "$KEYRING" ]; then
  log_info "Adding NVIDIA Container Toolkit signing key"
  curl -fsSL "$KEYRING_URL" | sudo gpg --dearmor -o "$KEYRING"
fi

if [ ! -f "$LIST" ]; then
  log_info "Adding NVIDIA Container Toolkit apt source"
  curl -fsSL "$LIST_URL" \
    | sed "s#deb https://#deb [signed-by=${KEYRING}] https://#g" \
    | sudo tee "$LIST" >/dev/null
fi

sudo apt-get update
apt_install nvidia-container-toolkit

log_info "Registering the NVIDIA runtime with docker"
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
