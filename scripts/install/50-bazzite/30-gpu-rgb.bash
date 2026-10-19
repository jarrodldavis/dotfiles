#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring Lenovo Legion GPU RGB...'
check_sudo

install_executable systemd/legion-gpu-rgb-off.sh /usr/local/sbin/legion-gpu-rgb-off
install_config systemd/legion-gpu-rgb-off-boot.service /etc/systemd/system/legion-gpu-rgb-off-boot.service
install_config systemd/legion-gpu-rgb-off-resume.service /etc/systemd/system/legion-gpu-rgb-off-resume.service

sudo systemctl --verbose daemon-reload
sudo systemctl --verbose enable --now legion-gpu-rgb-off-boot.service
sudo systemctl --verbose enable --now legion-gpu-rgb-off-resume.service
