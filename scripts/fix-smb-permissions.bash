#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step "Fixing SMB permissions..."

GRANTS=(
    list search add_file add_subdirectory delete_child
    readattr writeattr readextattr writeextattr
    readsecurity
    file_inherit directory_inherit
)
GRANTS_CSV=$(IFS=,; printf '%s' "${GRANTS[*]}")

op item get "$(scutil --get ComputerName)" --fields label=password --reveal |
    sudo --validate --stdin
echo

smb_paths=()
while IFS= read -r smb_path; do
    [[ -n "$smb_path" ]] && smb_paths+=("$smb_path")
done <<< "$(sharing -l -f json | jq -r '.[].path')"

for smb_path in "${smb_paths[@]}"; do
    log_step "$smb_path"

    log_substep "Setting recursive group permissions..."
    sudo chmod +a# 0 "group:staff allow $GRANTS_CSV" "$smb_path"

    log_substep "Updating ownership..."
    sudo chown -Rv "$(whoami)" "$smb_path"

    log_substep "Updating permissions..."
    sudo find "$smb_path" -type d -exec chmod -v 755 {} \;
    sudo find "$smb_path" -type f -exec chmod -v 644 {} \;
done

log_done "Done!"
