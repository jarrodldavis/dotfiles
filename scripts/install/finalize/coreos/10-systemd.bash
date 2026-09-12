#!/usr/bin/env bash
set -euo pipefail
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring systemd...'
systemctl --user enable --now podman.socket
