#!/usr/bin/env bash
# Slack via snap.
# Reference: https://slack.com/help/articles/212924728-Download-Slack-for-Linux--beta-

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

if ! is_installed snap; then
  log_info "Installing snapd"
  apt_install snapd
fi

if snap list slack >/dev/null 2>&1; then
  log_info "slack snap already installed, skipping"
  exit 0
fi

log_info "Installing slack via snap"
sudo snap install slack
