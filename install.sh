#!/usr/bin/env bash
# Top-level orchestrator. Runs all scripts/*.sh in numeric order.
# Usage: bash install.sh [--skip <name>] [--skip <name> ...]
#   <name> can be a script basename (e.g. 30-slack) or its prefix (e.g. 30).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT

# shellcheck source=scripts/lib.sh
source "${REPO_ROOT}/scripts/lib.sh"

SKIP=()
while [ $# -gt 0 ]; do
  case "$1" in
    --skip)
      [ $# -ge 2 ] || { log_err "--skip requires an argument"; exit 2; }
      SKIP+=("$2"); shift 2 ;;
    -h|--help)
      sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)
      log_err "unknown argument: $1"; exit 2 ;;
  esac
done

# --- preflight ---
if [ "$(id -u)" -eq 0 ]; then
  log_err "Do not run as root. The script will sudo as needed."
  exit 1
fi

if ! is_installed lsb_release; then
  log_info "Installing lsb-release for version detection"
  sudo apt-get update
  sudo apt-get install -y lsb-release
fi

UBUNTU_MAJOR="$(lsb_release -rs | awk -F. '{print $1}')"
if [ "$UBUNTU_MAJOR" -lt 22 ]; then
  log_err "Ubuntu 22.04 or newer is required (detected: $(lsb_release -ds))"
  exit 1
fi
log_info "Detected $(lsb_release -ds)"

log_info "Caching sudo credentials"
sudo -v

# sudo's credential cache expires after ~15 minutes, and a full run takes longer,
# so refresh it in the background until this script exits.
SUDO_KEEPALIVE_INTERVAL_SECONDS=60
keep_sudo_alive() {
  local parent_pid="$1"
  while kill -0 "$parent_pid" 2>/dev/null; do
    sudo -n true
    sleep "$SUDO_KEEPALIVE_INTERVAL_SECONDS"
  done
}
keep_sudo_alive "$$" >/dev/null 2>&1 &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# --- run scripts ---
should_skip() {
  local script="$1"
  local base
  base="$(basename "$script" .sh)"
  local prefix="${base%%-*}"
  local s
  for s in "${SKIP[@]:-}"; do
    [ -z "$s" ] && continue
    if [ "$s" = "$base" ] || [ "$s" = "$prefix" ]; then
      return 0
    fi
  done
  return 1
}

ran=()
skipped=()
for script in "${REPO_ROOT}"/scripts/[0-9]*.sh; do
  name="$(basename "$script" .sh)"
  if should_skip "$script"; then
    log_warn "Skipping $name"
    skipped+=("$name")
    continue
  fi
  log_info "===== Running $name ====="
  bash "$script"
  ran+=("$name")
done

# --- summary ---
echo
log_info "Setup complete."
log_info "Ran:     ${ran[*]:-<none>}"
log_info "Skipped: ${skipped[*]:-<none>}"
log_warn "Log out and log back in (or reboot) to apply IME and PATH changes."
# Repeats the warning from 82-nvidia-driver, which is buried in the log by now.
if has_nvidia_gpu && ! nvidia_smi_works; then
  log_warn "Reboot to activate the NVIDIA driver (nvidia-smi does not work yet)."
fi
