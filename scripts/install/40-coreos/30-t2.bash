#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring T2 Devices...'
check_sudo

cd ~/.dotfiles/configs/t2

log_substep 'Installing T2 Titan Ridge USB rules...'
sudo install --debug -D -o root -g root -m 0644 titan-ridge-usb.rules /etc/udev/rules.d/80-t2-titan-ridge-usb.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=pci
