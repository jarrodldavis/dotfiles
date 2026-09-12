#!/usr/bin/env bash
set -euo pipefail
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring systemd...'
systemctl --user daemon-reload
systemctl --user restart steam-download-inhibit.service
