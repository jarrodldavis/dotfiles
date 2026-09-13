#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring IPv6 localhost...'

# Disable IPv6 until Dev Containers support it correctly
# https://github.com/microsoft/vscode-remote-release/issues/7029

hosts=/etc/hosts

tmp=$(mktemp)
sed -E \
    '/^[[:space:]]*::1[[:space:]]+localhost([[:space:]]|$)/ s/^/#/' \
    "$hosts" >"$tmp"

if ! cmp -s "$hosts" "$tmp"; then
    cat "$tmp" | sudo tee "$hosts" >/dev/null
fi

rm -f "$tmp"
