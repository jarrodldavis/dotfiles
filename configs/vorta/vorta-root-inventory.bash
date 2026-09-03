#!/usr/bin/bash

set -euo pipefail

readonly backup_paths=/etc/vorta-system-inventory/root-backup-paths

die() {
    printf 'vorta-root-inventory: %s\n' "$*" >&2
    exit 1
}

etc_archive() {
    [[ -r "$backup_paths" ]] || die "cannot read $backup_paths"

    local path
    local -a paths=()

    while IFS= read -r path || [[ -n "$path" ]]; do
        path=${path%$'\r'}

        [[ -z "$path" ]] && continue
        [[ "$path" == \#* ]] && continue

        # Only allow paths beneath /etc.
        [[ "$path" == etc/* ]] || die "invalid path in allowlist: $path"

        case "/$path/" in
            */../*|*/./*)
                die "invalid path in allowlist: $path"
                ;;
        esac

        if [[ -e "/$path" || -L "/$path" ]]; then
            paths+=("$path")
        else
            printf 'warning: /%s does not exist; skipping\n' "$path" >&2
        fi
    done <"$backup_paths"

    ((${#paths[@]} > 0)) || die "allowlist contains no existing paths"

    exec /usr/bin/tar \
        -C / \
        --create \
        --file=- \
        --sort=name \
        --acls \
        --xattrs \
        --selinux \
        -- \
        "${paths[@]}"
}

[[ $# -eq 1 ]] || die "expected exactly one operation"

case "$1" in
    etc-archive)
        etc_archive
        ;;

    config-diff)
        exec /usr/bin/ostree admin config-diff
        ;;

    btrfs-filesystems)
        exec /usr/bin/btrfs filesystem show
        ;;

    btrfs-subvolumes)
        exec /usr/bin/btrfs subvolume list /sysroot
        ;;

    *)
        die "unsupported operation: $1"
        ;;
esac
