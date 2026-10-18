#!/usr/bin/env bash
set -Eeuo pipefail

on_error() {
    local rc=$?
    echo "ERROR: line $1: $2 (exit $rc)" >&2
}
trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR

echo '--> Starting CoreOS Borg maintenance...'

: "${CREDENTIALS_DIRECTORY:?Missing systemd credentials}"

REPO_AUTHORITY_FILE="$CREDENTIALS_DIRECTORY/repo_authority"
REPO_AUTHORITY="$(<"$REPO_AUTHORITY_FILE")"
REPO="ssh://$REPO_AUTHORITY/var/mnt/backup/coreos"

export BORG_EXIT_CODES=modern
export BORG_REPO="$REPO"
export BORG_PASSCOMMAND="cat $CREDENTIALS_DIRECTORY/passphrase"
export BORG_RSH="ssh -i $CREDENTIALS_DIRECTORY/ssh_key -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$CREDENTIALS_DIRECTORY/known_hosts"

echo '==> Verifying dependencies...'
command -v borg

case "${1:-}" in
    compact)
        echo "==> Pruning old archives..."
        borg --show-rc --lock-wait 3600 prune --verbose --stats \
            --glob-archives 'coreos-*' \
            --keep-daily 14 \
            --keep-weekly 8 \
            --keep-monthly 12

        echo "==> Compacting repository..."
        borg --show-rc --lock-wait 3600 compact --verbose

        ;;

    check)
        echo "==> Checking repository and archives..."
        borg --show-rc --lock-wait 3600 check --verbose
        ;;

    verify)
        echo "==> Cryptographically verifying archive data..."
        borg --show-rc --lock-wait 3600 check --verify-data --verbose
        ;;

    *)
        echo "Usage: $0 {compact|check|verify}" >&2
        exit 2
        ;;
esac

echo "--> Borg maintenance completed successfully."
