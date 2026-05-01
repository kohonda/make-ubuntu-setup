#!/usr/bin/env bash
# Base development packages.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

log_info "Updating apt index"
sudo apt-get update

apt_install \
  build-essential cmake git curl wget unzip ca-certificates gnupg \
  lsb-release tmux byobu htop ncdu tree jq python3-pip ufw \
  software-properties-common openssh-server net-tools terminator ffmpeg
