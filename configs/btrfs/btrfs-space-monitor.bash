#!/usr/bin/env bash
set -euo pipefail

mountpoint=/var/home
warning_bytes=$((20 * 1024 * 1024 * 1024))
critical_bytes=$((10 * 1024 * 1024 * 1024))
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/btrfs-space-monitor
state_file=$state_dir/level

usage=$(LC_ALL=C /usr/bin/btrfs filesystem usage -b "$mountpoint") || {
    echo "Unable to query Btrfs allocation for $mountpoint" >&2
    exit 1
}
unallocated=$(awk '$1 == "Device" && $2 == "unallocated:" { print $3; exit }' <<< "$usage")
if [[ ! $unallocated =~ ^[0-9]+$ ]]; then
    echo "Unable to parse Btrfs unallocated bytes for $mountpoint" >&2
    exit 1
fi

if (( unallocated < critical_bytes )); then
    level=critical
elif (( unallocated < warning_bytes )); then
    level=warning
else
    level=normal
fi

previous=unknown
[[ ! -f $state_file ]] || read -r previous < "$state_file" || true
[[ $level == "$previous" ]] && exit 0

gib=$(awk -v bytes="$unallocated" 'BEGIN { printf "%.1f", bytes / 1073741824 }')
case $level in
    critical)
        summary='Btrfs allocation critically low'
        body="$mountpoint has only $gib GiB unallocated (below 10 GiB). Check Btrfs maintenance immediately."
        urgency=critical
        ;;
    warning)
        summary='Btrfs allocation running low'
        body="$mountpoint has $gib GiB unallocated (below 20 GiB). Check Btrfs maintenance."
        urgency=normal
        ;;
    normal)
        summary='Btrfs allocation recovered'
        body="$mountpoint now has $gib GiB unallocated."
        urgency=low
        ;;
esac

echo "$summary: $body"
# Do not show a normal-state notification on the first run.
if [[ $previous != unknown || $level != normal ]]; then
    /usr/bin/notify-send --app-name='Btrfs Space Monitor' --urgency="$urgency" "$summary" "$body" || \
        echo 'Could not deliver Plasma desktop notification' >&2
fi

mkdir -p "$state_dir"
tmp=$(mktemp "$state_dir/.level.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
printf '%s\n' "$level" > "$tmp"
mv -f -- "$tmp" "$state_file"
