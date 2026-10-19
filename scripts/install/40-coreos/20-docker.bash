#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring Docker...'
check_sudo

log_substep 'Configuring Homebrew-installed CLI plugins...'
mkdir -pv ~/.docker
cat > ~/.docker/config.json <<EOF
{
    "cliPluginsExtraDirs": [
        "$(brew --prefix)/lib/docker/cli-plugins"
    ]
}
EOF

bat ~/.docker/config.json

log_substep 'Configuring user...'
sudo usermod -aG docker "$USER"

log_substep 'Configuring SELinux rules for mounted directories...'
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

bat "$SELINUX_RULES_FILE"

log_substep 'Configuring seccomp profile for Bubblewrap...'
DOCKER_CONFIG_DIR="/etc/docker"
SECCOMP_PROFILE="$DOCKER_CONFIG_DIR/seccomp-bwrap.json"
DAEMON_CONFIG="$DOCKER_CONFIG_DIR/daemon.json"

BWRAP_SYSCALLS='[
    "clone",
    "unshare",
    "mount",
    "mount_setattr",
    "umount",
    "umount2",
    "pivot_root",
    "setns"
]'

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

docker_version="$(docker version --format '{{.Server.Version}}')"
curl -fsSL \
    "https://raw.githubusercontent.com/moby/moby/docker-v${docker_version}/vendor/github.com/moby/profiles/seccomp/default.json" \
    -o "$tmpdir/seccomp-default.json"

jq --tab --argjson allow "$BWRAP_SYSCALLS" '
    .syscalls |= (
        map(
            .names -= $allow
            | select(.names | length > 0)
        )
        + [{
            "names": $allow,
            "action": "SCMP_ACT_ALLOW"
        }]
    )
' "$tmpdir/seccomp-default.json" > "$tmpdir/seccomp.json"

truncate -s -1 "$tmpdir/seccomp.json"
delta "$tmpdir/seccomp-default.json" "$tmpdir/seccomp.json" || [[ $? -eq 1 ]]

docker_changed=false

if ! cmp -s "$tmpdir/seccomp.json" "$SECCOMP_PROFILE"; then
    install_config "$tmpdir/seccomp.json" "$SECCOMP_PROFILE"
    docker_changed=true
fi

if test -f "$DAEMON_CONFIG"; then
    cat "$DAEMON_CONFIG" > "$tmpdir/daemon-original.json"
else
    printf '{}\n' > "$tmpdir/daemon-original.json"
fi

jq --arg profile "$SECCOMP_PROFILE" '
    . + {"seccomp-profile": $profile}
' "$tmpdir/daemon-original.json" > "$tmpdir/daemon.json"

if ! cmp -s "$tmpdir/daemon.json" "$DAEMON_CONFIG"; then
    install_config "$tmpdir/daemon.json" "$DAEMON_CONFIG"
    docker_changed=true
fi

bat "$DAEMON_CONFIG"

log_substep 'Configuring Bubblewrap SELinux policy...'
cat > "$tmpdir/bwrap-container.cil" <<'EOF'
(allow container_t devpts_t (filesystem (mount)))
(allow container_t proc_t (filesystem (mount)))
(allow container_t tmpfs_t (filesystem (remount)))
EOF

sudo semodule -vi "$tmpdir/bwrap-container.cil"

if [[ "$docker_changed" == true ]]; then
    log_substep 'Restarting Docker...'
    sudo systemctl restart docker
fi
