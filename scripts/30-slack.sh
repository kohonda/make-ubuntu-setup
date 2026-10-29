#!/usr/bin/env bash
# Slack via the official .deb. The snap build cannot load the fcitx5 input
# module because of its confinement, so Japanese input does not work there.
# Reference: https://slack.com/help/articles/212924728-Download-Slack-for-Linux--beta-

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

SLACK_ARCH=amd64
SLACK_DOWNLOAD_PAGE='https://slack.com/downloads/instructions/linux?build=deb'
SLACK_DEB_URL_PATTERN='https://downloads\.slack-edge\.com/[^"]*slack-desktop-[^"]*-amd64\.deb'
# Used when the download page cannot be read or no longer carries the link.
SLACK_FALLBACK_VERSION=4.52.182
SLACK_FALLBACK_URL="https://downloads.slack-edge.com/desktop-releases/linux/x64/${SLACK_FALLBACK_VERSION}/slack-desktop-${SLACK_FALLBACK_VERSION}-amd64.deb"

find_latest_slack_deb_url() {
  curl -fsSL "$SLACK_DOWNLOAD_PAGE" | grep -oE -m1 "$SLACK_DEB_URL_PATTERN"
}

if is_installed snap && snap list slack >/dev/null 2>&1; then
  log_warn "The snap build of Slack is installed and cannot use Japanese input."
  log_warn "Remove it with 'sudo snap remove slack' once the .deb build works for you."
fi

if [ "$(dpkg --print-architecture)" != "$SLACK_ARCH" ]; then
  log_warn "Slack .deb is only published for ${SLACK_ARCH}, skipping"
  exit 0
fi

if dpkg_installed slack-desktop; then
  log_info "slack-desktop already installed, skipping"
  exit 0
fi

if ! slack_deb_url="$(find_latest_slack_deb_url)"; then
  log_warn "Could not read the latest Slack URL; falling back to ${SLACK_FALLBACK_VERSION}"
  slack_deb_url="$SLACK_FALLBACK_URL"
fi
install_deb_from_url "$slack_deb_url"
