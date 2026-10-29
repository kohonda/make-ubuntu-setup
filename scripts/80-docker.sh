#!/usr/bin/env bash
# Docker Engine + Buildx + Compose plugin via the official Docker apt repository.
# Reference: https://docs.docker.com/engine/install/ubuntu/

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

KEYRING=/etc/apt/keyrings/docker.asc
KEYRING_URL=https://download.docker.com/linux/ubuntu/gpg
LIST=/etc/apt/sources.list.d/docker.list
DOCKER_GROUP=docker
TARGET_USER="${USER:-$(id -un)}"
DOCKER_PACKAGES=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
# The unofficial packages Docker's install guide says to remove first.
CONFLICTING_PACKAGES=(docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc)

remove_conflicting_packages() {
  local installed=()
  local package
  for package in "${CONFLICTING_PACKAGES[@]}"; do
    if dpkg_installed "$package"; then
      installed+=("$package")
    fi
  done
  if [ ${#installed[@]} -gt 0 ]; then
    log_info "Removing conflicting packages: ${installed[*]}"
    sudo apt-get remove -y "${installed[@]}"
  fi
}

add_docker_apt_source() {
  sudo install -d -m 0755 /etc/apt/keyrings
  if [ ! -f "$KEYRING" ]; then
    log_info "Adding Docker signing key"
    sudo curl -fsSL "$KEYRING_URL" -o "$KEYRING"
    sudo chmod a+r "$KEYRING"
  fi
  if [ ! -f "$LIST" ]; then
    local codename
    # shellcheck source=/dev/null
    codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
    log_info "Adding Docker apt source"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=${KEYRING}] https://download.docker.com/linux/ubuntu ${codename} stable" \
      | sudo tee "$LIST" >/dev/null
  fi
}

# An installed docker-ce came from some Docker source already; writing ours next
# to one with another Signed-By path would make apt fail with "Conflicting values".
if dpkg_installed docker-ce; then
  log_info "docker-ce already installed, skipping package setup"
else
  remove_conflicting_packages
  add_docker_apt_source
  sudo apt-get update
  apt_install "${DOCKER_PACKAGES[@]}"
fi

if id -nG "$TARGET_USER" | tr ' ' '\n' | grep -qx "$DOCKER_GROUP"; then
  log_info "$TARGET_USER is already in the $DOCKER_GROUP group"
else
  log_info "Adding $TARGET_USER to the $DOCKER_GROUP group"
  sudo usermod -aG "$DOCKER_GROUP" "$TARGET_USER"
  log_warn "Log out and log back in to run docker without sudo."
fi

sudo systemctl enable --now docker
