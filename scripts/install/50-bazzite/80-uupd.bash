#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Configuring uupd...'
check_sudo

tmp="$(mktemp)"
jq -s '.[0] // {} | .modules.distrobox.disable = false' \
    < <(cat /etc/uupd/config.json 2>/dev/null || true) > "$tmp"
sudo install -m 0644 "$tmp" /etc/uupd/config.json
rm -f "$tmp"

log_info 'uupd config:'
uupd config-dump
