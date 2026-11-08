#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

check_sudo

config=root
subvolume=/var/home

log_substep 'Enabling snapshots...'
ujust configure-snapshots enable

configured_subvolume=$(sudo snapper -c "$config" get-config | awk '$1 == "SUBVOLUME" { print $3 }')
if [[ "$configured_subvolume" != "$subvolume" ]]; then
    log_error "Snapper config '$config' targets '$configured_subvolume', expected '$subvolume'." >&2
    exit 1
fi

log_substep 'Updating snapshot timeline config...'
# Retain up to three units of the next-largest time interval:
# 72 hourly snapshots (3 days), 21 daily snapshots (3 weeks), and 12 weekly snapshots (3 months).
sudo snapper -c "$config" set-config \
    'TIMELINE_CREATE=yes' \
    'TIMELINE_CLEANUP=yes' \
    'TIMELINE_MIN_AGE=1800' \
    'TIMELINE_LIMIT_HOURLY=72' \
    'TIMELINE_LIMIT_DAILY=21' \
    'TIMELINE_LIMIT_WEEKLY=12' \
    'TIMELINE_LIMIT_MONTHLY=0' \
    'TIMELINE_LIMIT_QUARTERLY=0' \
    'TIMELINE_LIMIT_YEARLY=0' \
    'NUMBER_CLEANUP=yes' \
    'NUMBER_LIMIT=0' \
    'NUMBER_LIMIT_IMPORTANT=0' \
    'NUMBER_MIN_AGE=1800' \
    'EMPTY_PRE_POST_CLEANUP=yes' \
    'EMPTY_PRE_POST_MIN_AGE=3600' \
    'QGROUP='

log_info 'Snapper Config:'
sudo snapper -c "$config" get-config
