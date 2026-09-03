#!/usr/bin/env zsh
set -euo pipefail

cd ~/.dotfiles/configs/vorta

mkdir -pv ~/.local/bin
install --debug -m 0700 update-system-inventory.bash ~/.local/bin/update-system-inventory

sudo install --debug -o root -g root -m 0755 vorta-root-inventory.bash /usr/local/sbin/vorta-root-inventory

sudo install --debug -d -o root -g root -m 0755 /etc/vorta-system-inventory
sudo install --debug -o root -g root -m 0644 root-backup-paths /etc/vorta-system-inventory/root-backup-paths

sudo visudo -cf vorta-system-inventory.sudoers
sudo install --debug -o root -g root -m 0440 vorta-system-inventory.sudoers /etc/sudoers.d/vorta-system-inventory
sudo visudo -cf /etc/sudoers.d/vorta-system-inventory
