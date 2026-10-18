#!/usr/bin/env bash
set -Eeuo pipefail

on_error() {
    local rc=$?
    echo "ERROR: line $1: $2 (exit $rc)" >&2
}
trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR

echo '--> Starting CoreOS Borg backup...'

: "${CREDENTIALS_DIRECTORY:?Missing systemd credentials}"

REPO_AUTHORITY_FILE="$CREDENTIALS_DIRECTORY/repo_authority"
REPO_AUTHORITY="$(<"$REPO_AUTHORITY_FILE")"
REPO="ssh://$REPO_AUTHORITY/var/mnt/backup/coreos"

VOLUME_ROOT="/var/lib/docker/volumes"

export BORG_EXIT_CODES=modern
export BORG_REPO="$REPO"
export BORG_PASSCOMMAND="cat $CREDENTIALS_DIRECTORY/passphrase"
export BORG_RSH="ssh -i $CREDENTIALS_DIRECTORY/ssh_key -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$CREDENTIALS_DIRECTORY/known_hosts"

echo '==> Verifying dependencies and filesystem availability...'
command -v borg
command -v docker
docker info
test -d "$VOLUME_ROOT"

echo '==> Discovering Docker volumes...'
volume_list="$(docker volume ls --format '{{.Name}}')"

if [[ -z "$volume_list" ]]; then
    echo "No Docker volumes found; refusing empty backup" >&2
    exit 1
fi

mapfile -t volumes <<< "$volume_list"

paths=()

for volume in "${volumes[@]}"; do
    driver="$(docker volume inspect -f '{{.Driver}}' "$volume")"
    mount="$(docker volume inspect -f '{{.Mountpoint}}' "$volume")"
    expected="$VOLUME_ROOT/$volume/_data"

    if [[ "$driver" != "local" || "$mount" != "$expected" ]]; then
        echo "Unexpected volume configuration: $volume" >&2
        exit 1
    fi

    if [[ ! -d "$mount" ]]; then
        echo "Volume directory missing: $mount" >&2
        exit 1
    fi

    paths+=("$volume/_data")
done

echo "==> Backing up ${#paths[@]} Docker volumes..."
cd "$VOLUME_ROOT"

borg --show-rc --lock-wait 3600 create --verbose --stats \
    --compression zstd,3 \
    "$BORG_REPO::coreos-{now:%Y-%m-%dT%H:%M:%S}" \
    "${paths[@]}"

echo "--> CoreOS Borg backup completed successfully!"
