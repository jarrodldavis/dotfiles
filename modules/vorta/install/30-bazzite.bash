#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Configuring Vorta System Inventory...'
check_sudo

mkdir -pv ~/.local/bin
symlink update-system-inventory.bash ~/.local/bin/update-system-inventory

install_executable vorta-root-inventory.bash /usr/local/sbin/vorta-root-inventory
install_config root-backup-paths /etc/vorta-system-inventory/root-backup-paths

install_readonly_secret vorta-system-inventory.sudoers /etc/sudoers.d/vorta-system-inventory
sudo visudo -cf /etc/sudoers.d/vorta-system-inventory

log_substep 'Configuring Vorta Watchdog...'
symlink vorta-watchdog.bash ~/.local/bin/vorta-watchdog
symlink vorta-watchdog.service ~/.config/systemd/user/vorta-watchdog.service
symlink vorta-watchdog.timer ~/.config/systemd/user/vorta-watchdog.timer
systemctl --user --verbose daemon-reload
systemctl --user --verbose enable --now vorta-watchdog.timer
