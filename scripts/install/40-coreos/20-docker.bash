#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring Docker...'

mkdir -pv ~/.docker
cat > ~/.docker/config.json <<EOF
{
    "cliPluginsExtraDirs": [
        "$(brew --prefix)/lib/docker/cli-plugins"
    ]
}
EOF

sudo usermod -aG docker "$USER"

ROOTS=("$HOME/git" "$HOME/.dotfiles")
SELINUX_RULES_FILE="/etc/selinux/targeted/contexts/files/file_contexts.local"

for root in "${ROOTS[@]}"; do
    mkdir -pv "$root"
    selinux_rule="$root(/.*)?    system_u:object_r:container_file_t:s0"
    if ! grep -qF "$selinux_rule" "$SELINUX_RULES_FILE"; then
        echo "$selinux_rule" | sudo tee -a "$SELINUX_RULES_FILE" >/dev/null
    fi
    sudo restorecon -RFv "$root"
done
