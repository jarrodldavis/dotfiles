#!/usr/bin/bash

set -uo pipefail

umask 077

output="$HOME/.config/system-inventory"
root_helper=/usr/local/sbin/vorta-root-inventory

# flatpak-spawn --host does not run a login shell, so include Homebrew explicitly.
export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/usr/local/bin:/usr/bin:/bin:$PATH"

mkdir -p "$output" || exit 1

replace_if_changed() {
    local source=$1
    local destination=$2

    if [[ -e "$destination" ]] && cmp -s "$source" "$destination"; then
        rm -f "$source"
    else
        mv -f "$source" "$destination"
    fi
}

capture() {
    local filename=$1
    shift

    local stdout_tmp stderr_tmp status

    stdout_tmp=$(mktemp "$output/.${filename}.stdout.XXXXXX") || return 1
    stderr_tmp=$(mktemp "$output/.${filename}.stderr.XXXXXX") || {
        rm -f "$stdout_tmp"
        return 1
    }

    if "$@" >"$stdout_tmp" 2>"$stderr_tmp"; then
        status=0
    else
        status=$?

        if [[ -s "$stderr_tmp" ]]; then
            {
                printf '\n## stderr\n\n'
                cat "$stderr_tmp"
            } >>"$stdout_tmp"
        fi

        printf '\n[command exited with status %d]\n' "$status" >>"$stdout_tmp"
    fi

    rm -f "$stderr_tmp"
    replace_if_changed "$stdout_tmp" "$output/$filename"

    return "$status"
}

metadata() {
    printf 'Host: %s\n' "$(hostname)"
    printf 'Kernel: %s\n' "$(uname -srmo)"

    if [[ -r /etc/os-release ]]; then
        printf '\n## OS\n\n'
        cat /etc/os-release
    fi
}

flatpak_overrides() {
    printf '## User global overrides\n\n'
    flatpak override --user --show 2>&1 || true

    printf '\n## System global overrides\n\n'
    flatpak override --system --show 2>&1 || true

    while IFS= read -r app; do
        printf '\n## %s — user overrides\n\n' "$app"
        flatpak override --user --show "$app" 2>&1 || true

        printf '\n## %s — system overrides\n\n' "$app"
        flatpak override --system --show "$app" 2>&1 || true
    done < <(flatpak list --app --columns=application)
}

brewfile() {
    local tmp status

    tmp=$(mktemp) || return 1

    if brew bundle dump --force --file="$tmp" >/dev/null; then
        cat "$tmp"
        status=0
    else
        status=$?
    fi

    rm -f "$tmp"
    return "$status"
}

podman_inventory() {
    local status=0

    printf '## Containers\n\n'
    podman ps -a \
        --format 'table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.Status}}\t{{.Names}}' \
        || status=$?

    printf '\n## Volumes\n\n'
    podman volume ls || status=$?

    printf '\n## Images\n\n'
    podman images \
        --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}' \
        || status=$?

    return "$status"
}

btrfs_inventory() {
    local status=0

    printf '## Filesystems\n\n'
    sudo -n "$root_helper" btrfs-filesystems || status=$?

    printf '\n## Subvolumes — system filesystem\n\n'
    sudo -n "$root_helper" btrfs-subvolumes || status=$?

    return "$status"
}

root_etc_archive() {
    local archive="$output/root-etc.tar"
    local manifest="$output/root-etc-files.txt"
    local error="$output/root-etc.error.txt"
    local warnings="$output/root-etc.warnings.txt"

    local archive_tmp manifest_tmp stderr_tmp status

    archive_tmp=$(mktemp "$output/.root-etc.tar.XXXXXX") || return 1
    manifest_tmp=$(mktemp "$output/.root-etc-files.XXXXXX") || {
        rm -f "$archive_tmp"
        return 1
    }
    stderr_tmp=$(mktemp "$output/.root-etc.stderr.XXXXXX") || {
        rm -f "$archive_tmp" "$manifest_tmp"
        return 1
    }

    if sudo -n "$root_helper" etc-archive >"$archive_tmp" 2>"$stderr_tmp"; then
        if tar -tf "$archive_tmp" >"$manifest_tmp"; then
	    replace_if_changed "$archive_tmp" "$archive"
            replace_if_changed "$manifest_tmp" "$manifest"
            rm -f "$error"

            if [[ -s "$stderr_tmp" ]]; then
                replace_if_changed "$stderr_tmp" "$warnings"
            else
                rm -f "$stderr_tmp" "$warnings"
            fi

            return 0
        fi

        status=$?
        printf 'Generated archive failed tar validation.\n' >"$stderr_tmp"
    else
        status=$?
    fi

    rm -f "$archive_tmp" "$manifest_tmp" "$archive" "$manifest" "$warnings"
    mv -f "$stderr_tmp" "$error"
    printf '\n[backup helper exited with status %d]\n' "$status" >>"$error"

    return "$status"
}

tang_archive() {
    local source="$HOME/.local/share/tang"
    local archive="$output/tang.tar"
    local manifest="$output/tang-files.txt"
    local error="$output/tang.error.txt"
    local warnings="$output/tang.warnings.txt"

    local archive_tmp manifest_tmp stderr_tmp status

    archive_tmp=$(mktemp "$output/.tang.tar.XXXXXX") || return 1
    manifest_tmp=$(mktemp "$output/.tang-files.XXXXXX") || {
        rm -f "$archive_tmp"
        return 1
    }
    stderr_tmp=$(mktemp "$output/.tang.stderr.XXXXXX") || {
        rm -f "$archive_tmp" "$manifest_tmp"
        return 1
    }

    if podman unshare tar \
        --sort=name \
        --acls \
        --xattrs \
        --selinux \
        -C "$source" \
        -cf - \
        . >"$archive_tmp" 2>"$stderr_tmp"; then
        if tar -tf "$archive_tmp" >"$manifest_tmp"; then
            replace_if_changed "$archive_tmp" "$archive"
            replace_if_changed "$manifest_tmp" "$manifest"
            rm -f "$error"

            if [[ -s "$stderr_tmp" ]]; then
                replace_if_changed "$stderr_tmp" "$warnings"
            else
                rm -f "$stderr_tmp" "$warnings"
            fi

            return 0
        fi

        status=$?
        printf 'Generated archive failed tar validation.\n' >"$stderr_tmp"
    else
        status=$?
    fi

    rm -f "$archive_tmp" "$manifest_tmp" "$archive" "$manifest" "$warnings"
    mv -f "$stderr_tmp" "$error"
    printf '\n[Tang archive exited with status %d]\n' "$status" >>"$error"

    return "$status"
}

capture metadata.txt metadata

# Privileged /etc files Vorta cannot read directly.
root_etc_archive || true

# Bazzite / OSTree
capture rpm-ostree.txt rpm-ostree status
capture kernel-arguments.txt rpm-ostree kargs
capture etc-config-diff.txt sudo -n "$root_helper" config-diff

# Flatpak
capture flatpaks.txt flatpak list --app --columns=application,origin,installation
capture flatpak-remotes.txt flatpak remotes --show-details
capture flatpak-overrides.txt flatpak_overrides

# Homebrew
if command -v brew >/dev/null; then
    capture Brewfile brewfile
else
    printf '[brew not found]\n' >"$output/Brewfile"
fi

# systemd
capture systemd-enabled.txt systemctl list-unit-files --state=enabled --no-pager
capture systemd-masked.txt systemctl list-unit-files --state=masked --no-pager
capture systemd-user-enabled.txt systemctl --user list-unit-files --state=enabled --no-pager
capture systemd-user-masked.txt systemctl --user list-unit-files --state=masked --no-pager
capture systemd-user-linger.txt loginctl show-user "$USER" -p Linger

# Storage
capture block-devices.txt \
    lsblk -o NAME,PATH,SIZE,FSTYPE,FSVER,LABEL,UUID,PARTLABEL,PARTUUID,MOUNTPOINTS

capture mounts.txt \
    findmnt --real -o TARGET,SOURCE,FSTYPE,OPTIONS

if command -v btrfs >/dev/null; then
    capture btrfs.txt btrfs_inventory
else
    printf '[btrfs not found]\n' >"$output/btrfs.txt"
fi

# Containers
if command -v distrobox >/dev/null; then
    capture distroboxes.txt distrobox list
else
    printf '[distrobox not found]\n' >"$output/distroboxes.txt"
fi

if command -v podman >/dev/null; then
    capture podman.txt podman_inventory

    # Tang data is owned by UIDs in the rootless Podman user namespace.
    tang_archive || true
else
    printf '[podman not found]\n' >"$output/podman.txt"
fi
