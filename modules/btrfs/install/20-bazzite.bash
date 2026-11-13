#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

module_dir="$HOME/.dotfiles/modules/btrfs"

log_substep 'Configuring maintenance...'
check_sudo
install_config "$module_dir/btrfsmaintenance.conf" /etc/sysconfig/btrfsmaintenance
sudo systemctl restart btrfsmaintenance-refresh.service

log_substep 'Configuring monitor...'
symlink "$module_dir/btrfs-space-monitor.bash" ~/.local/bin/btrfs-space-monitor
symlink "$module_dir/btrfs-space-monitor.service" ~/.config/systemd/user/btrfs-space-monitor.service
symlink "$module_dir/btrfs-space-monitor.timer" ~/.config/systemd/user/btrfs-space-monitor.timer
systemctl --verbose --user daemon-reload
systemctl --verbose --user enable btrfs-space-monitor.timer
