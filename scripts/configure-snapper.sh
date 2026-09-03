#!/usr/bin/env zsh
set -euo pipefail

config=root
subvolume=/var/home

# Let Bazzite create and enable its standard Snapper configuration.
ujust configure-snapshots enable

configured_subvolume=$(sudo snapper -c "$config" get-config | awk '$1 == "SUBVOLUME" { print $3 }')

if [[ "$configured_subvolume" != "$subvolume" ]]; then
    echo "Snapper config '$config' targets '$configured_subvolume', expected '$subvolume'." >&2
    exit 1
fi

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

# Snapper requires full Btrfs qgroups, rather than simple quotas, for space-aware cleanup.
qgroup=$(sudo snapper -c "$config" get-config | awk '$1 == "QGROUP" { print $3 }')

if [[ -z "$qgroup" ]]; then
    sudo snapper -c "$config" setup-quota
fi

# Snapshot deletion can make qgroup accounting inconsistent because of Btrfs's drop-subtree optimization. Rescan
# before and after cleanup so Snapper always has valid exclusive-space accounting.
sudo btrfs quota rescan -w "$subvolume"
sudo snapper -c "$config" cleanup timeline
sudo btrfs quota rescan -w "$subvolume"

# A cleanup can stop after deletion makes qgroup accounting inconsistent, so run a second pass with fresh accounting.
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
