#!/usr/bin/env bash
set -euo pipefail

if ! /usr/bin/findmnt --mountpoint /var/mnt/backup >/dev/null; then
    echo "Backup drive is not mounted" >&2
    exit 1
fi

exec /home/linuxbrew/.linuxbrew/bin/borg serve --restrict-to-repository /var/mnt/backup/coreos
