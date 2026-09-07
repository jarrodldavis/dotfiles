#!/usr/bin/env zsh
set -euo pipefail

cd ~/.dotfiles/configs/systemd

sudo install --debug -o root -g root -m 0755 legion-gpu-rgb-off.sh /usr/local/sbin/legion-gpu-rgb-off
sudo install --debug -o root -g root -m 0644 legion-gpu-rgb-off.service /etc/systemd/system/legion-gpu-rgb-off.service

sudo systemctl daemon-reload
sudo systemctl enable --now legion-gpu-rgb-off.service
