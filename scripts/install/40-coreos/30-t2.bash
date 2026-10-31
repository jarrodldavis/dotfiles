#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

check_sudo

log_substep 'Installing T2 Titan Ridge USB rules...'
install_config t2/titan-ridge-usb.rules /etc/udev/rules.d/80-t2-titan-ridge-usb.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=pci
