#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring systemd...'
systemctl --user --verbose daemon-reload
systemctl --user --verbose restart steam-download-inhibit.service
systemctl --user --verbose enable --now coreos-update-wake.timer
systemctl --user --verbose restart tang.service

log_substep 'Enabling user session linger...'
loginctl enable-linger "$USER"
loginctl show-user "$USER"
