#!/usr/bin/env zsh
set -euo pipefail

config=root
subvolume=/var/home

echo '==> Enabling snapshots...'
ujust configure-snapshots enable

configured_subvolume=$(sudo snapper -c "$config" get-config | awk '$1 == "SUBVOLUME" { print $3 }')
if [[ "$configured_subvolume" != "$subvolume" ]]; then
    echo "Snapper config '$config' targets '$configured_subvolume', expected '$subvolume'." >&2
    exit 1
fi

echo '==> Updating snapshot timeline config...'
# Normally retain up to three units of the next-largest time interval, with one unit as the space-aware minimum:
# 24-72 hourly snapshots (1-3 days), 7-21 daily snapshots (1-3 weeks), and 4-12 weekly snapshots (1-3 months).
sudo snapper -c "$config" set-config \
    'TIMELINE_CREATE=yes' \
    'TIMELINE_CLEANUP=yes' \
    'TIMELINE_MIN_AGE=1800' \
    'TIMELINE_LIMIT_HOURLY=24-72' \
    'TIMELINE_LIMIT_DAILY=7-21' \
    'TIMELINE_LIMIT_WEEKLY=4-12' \
    'TIMELINE_LIMIT_MONTHLY=0' \
    'TIMELINE_LIMIT_QUARTERLY=0' \
    'TIMELINE_LIMIT_YEARLY=0' \
    'NUMBER_CLEANUP=yes' \
    'NUMBER_LIMIT=0' \
    'NUMBER_LIMIT_IMPORTANT=0' \
    'NUMBER_MIN_AGE=1800' \
    'EMPTY_PRE_POST_CLEANUP=yes' \
    'EMPTY_PRE_POST_MIN_AGE=3600' \
    'SPACE_LIMIT=0.25' \
    'FREE_LIMIT=0.2'

echo '==> Setting up Snapper quotas...'
qgroup=$(sudo snapper -c "$config" get-config | awk '$1 == "QGROUP" { print $3 }')
if [[ -z "$qgroup" ]]; then
    sudo snapper -c "$config" setup-quota
fi

echo '==> Installing Snapper cleanup systemd override...'
cd ~/.dotfiles/configs/systemd
sudo install --debug -D -o root -g root -m 0644 snapper-cleanup.service.override.conf /etc/systemd/system/snapper-cleanup.service.d/override.conf
sudo systemctl daemon-reload

echo '==> Performing Snapper cleanup...'
sudo snapper -c "$config" cleanup timeline
sudo btrfs quota rescan -w "$subvolume"

echo
sudo snapper -c "$config" get-config | grep -E '^(QGROUP|SPACE_LIMIT|FREE_LIMIT|TIMELINE_(CREATE|CLEANUP|MIN_AGE|LIMIT_))'

echo
sudo btrfs quota status "$subvolume"

echo
qgroup=$(sudo snapper -c "$config" get-config | awk '$1 == "QGROUP" { print $3 }')
if [[ -n "$qgroup" ]]; then
    sudo btrfs qgroup show -re "$subvolume" | awk -v qgroup="$qgroup" 'NR <= 2 || $1 == qgroup'
fi
