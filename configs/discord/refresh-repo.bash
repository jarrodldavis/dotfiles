#!/usr/bin/env bash
set -euo pipefail

repo=/var/lib/discord-rpm-repo
stamp="$repo/.last-check"
url='https://discord.com/api/download?platform=linux&format=rpm'

# DNF invokes hooks for non-upgrade commands too. Only mutate as root.
(( EUID == 0 )) || exit 0

install -d -m 0755 "$repo"
exec 9>"$repo/.refresh.lock"
flock -x 9

if [[ ${1-} != --force && -f $stamp ]]; then
    if (( $(date +%s) - $(stat -c %Y "$stamp") < 21600 )); then
        exit 0
    fi
fi

tmp=$(mktemp "$repo/.discord-download.XXXXXXXX.rpm")
trap 'rm -f -- "$tmp"' EXIT

if ! curl --fail --location --retry 2 --connect-timeout 15 --max-time 180 \
    --output "$tmp" "$url"; then
    printf 'Discord RPM refresh: download failed; retaining existing repository.\n' >&2
    exit 0
fi

name=$(rpm -qp --qf '%{NAME}' "$tmp")
arch=$(rpm -qp --qf '%{ARCH}' "$tmp")
[[ $name == discord && $arch == x86_64 ]] || {
    printf 'Discord RPM refresh: unexpected package %s (%s).\n' "$name" "$arch" >&2
    exit 1
}

version=$(rpm -qp --qf '%{EPOCHNUM}:%{VERSION}-%{RELEASE}' "$tmp")
filename=$(rpm -qp --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm' "$tmp")
destination="$repo/$filename"

if [[ ! -f $destination ]]; then
    printf 'Discord RPM refresh: downloading %s.\n' "$version" >&2
    mv -- "$tmp" "$destination"
    chmod 0644 "$destination"
fi

if [[ ! -f "$repo/repodata/repomd.xml" ||
      "$destination" -nt "$repo/repodata/repomd.xml" ]]; then
    createrepo_c --update "$repo" >&2
fi

touch "$stamp"
