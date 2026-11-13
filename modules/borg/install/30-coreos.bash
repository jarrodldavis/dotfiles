#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

module_dir="$HOME/.dotfiles/modules/borg"

check_sudo

install_executable "$module_dir/coreos-borg-backup.bash" /usr/local/sbin/coreos-borg-backup
install_config "$module_dir/coreos-borg-backup.service" /etc/systemd/system/coreos-borg-backup.service
install_config "$module_dir/coreos-borg-backup.timer" /etc/systemd/system/coreos-borg-backup.timer

install_executable "$module_dir/coreos-borg-maintenance.bash" /usr/local/sbin/coreos-borg-maintenance
install_config "$module_dir/coreos-borg-maintenance@.service" /etc/systemd/system/coreos-borg-maintenance@.service
install_config "$module_dir/coreos-borg-maintenance@check.timer" /etc/systemd/system/coreos-borg-maintenance@check.timer
install_config "$module_dir/coreos-borg-maintenance@compact.timer" /etc/systemd/system/coreos-borg-maintenance@compact.timer

sudo systemctl --verbose daemon-reload
sudo systemctl --verbose enable --now coreos-borg-backup.timer coreos-borg-maintenance@compact.timer coreos-borg-maintenance@check.timer
