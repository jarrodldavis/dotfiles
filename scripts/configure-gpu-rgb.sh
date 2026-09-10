#!/usr/bin/env zsh
set -euo pipefail

cd ~/.dotfiles/configs/systemd

sudo install --debug -D -o root -g root -m 0755 legion-gpu-rgb-off.sh /usr/local/sbin/legion-gpu-rgb-off
sudo install --debug -D -o root -g root -m 0644 legion-gpu-rgb-off-boot.service /etc/systemd/system/legion-gpu-rgb-off-boot.service
sudo install --debug -D -o root -g root -m 0644 legion-gpu-rgb-off-resume.service /etc/systemd/system/legion-gpu-rgb-off-resume.service

sudo systemctl daemon-reload
sudo systemctl enable --now legion-gpu-rgb-off-boot.service
sudo systemctl enable --now legion-gpu-rgb-off-resume.service
