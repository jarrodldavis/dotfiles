#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Setting up CoreOS Borg backups...'

log_bell
read -r -p 'Borg repo authority (user@host.local): ' repo_authority
printf '\n'

repo_host="${repo_authority#*@}"

log_substep 'Preparing SSH connection...'
ssh_control_dir="$(mktemp -d)"
chmod 700 "$ssh_control_dir"

ssh_control_config="$HOME/.ssh/config.local.d/coreos-borg-setup"
cat > "$ssh_control_config" <<EOF
Host $repo_host
    ControlMaster auto
    ControlPath $ssh_control_dir/control-%C
    ControlPersist yes
EOF
chmod 600 "$ssh_control_config"

cleanup_ssh() {
    ssh -O exit "$repo_authority" 2>/dev/null || true
    rm -f "$ssh_control_config"
    rm -rf "$ssh_control_dir"
}
trap cleanup_ssh EXIT

log_bell
log_warning 'SSH access is required:'
ssh -MNf "$repo_authority"

log_substep 'Verifying remote backup environment...'
ssh "$repo_authority" '
    findmnt --mountpoint /var/mnt/backup >/dev/null &&
    test -x "$HOME/.local/bin/borg-backup-server" &&
    test -d /var/mnt/backup/coreos
'

log_substep 'Removing existing Borg SSH keys from remote...'
ssh "$repo_authority" "sed -i '/coreos-borg-backup/d' ~/.ssh/authorized_keys || true"

log_substep 'Generating Borg SSH key...'
rm -f ~/.ssh/id_ed25519_borg ~/.ssh/id_ed25519_borg.pub
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_borg -C "coreos-borg-backup" -N ""

log_substep 'Uploading new Borg SSH key to remote...'
ssh-copy-id -f -i ~/.ssh/id_ed25519_borg.pub "$repo_authority"

log_substep 'Editing authorized_keys to restrict backup SSH key to Borg...'
ssh "$repo_authority" bash -s < ~/.dotfiles/scripts/restrict-borg-backup-key.bash

log_substep 'Initializing Borg repository on remote...'
export BORG_EXIT_CODES=modern
export BORG_RSH="ssh -i $HOME/.ssh/id_ed25519_borg -o IdentitiesOnly=yes -o BatchMode=yes -o ControlMaster=no -o ControlPath=none"
borg --show-rc init --encryption=repokey-blake2 "ssh://$repo_authority/var/mnt/backup/coreos" || [[ $? -eq 10 ]]

log_substep 'Preparing credentials for system service...'
check_sudo
install_secret /home/core/.ssh/id_ed25519_borg /etc/coreos-borg/ssh_key
install_secret /home/core/.ssh/known_hosts /etc/coreos-borg/known_hosts
printf '%s\n' "$repo_authority" | install_secret /dev/stdin /etc/coreos-borg/repo_authority

log_bell
log_warning 'Borg repo access is required:'
read -rs -p 'Borg passphrase: ' passphrase
printf '\n'
printf '%s\n' "$passphrase" | install_secret /dev/stdin /etc/coreos-borg/passphrase
unset passphrase

log_substep 'Installing systemd services...'
check_sudo

install_executable borg/coreos-borg-backup.bash /usr/local/sbin/coreos-borg-backup
install_config borg/coreos-borg-backup.service /etc/systemd/system/coreos-borg-backup.service
install_config borg/coreos-borg-backup.timer /etc/systemd/system/coreos-borg-backup.timer

install_executable borg/coreos-borg-maintenance.bash /usr/local/sbin/coreos-borg-maintenance
install_config borg/coreos-borg-maintenance@.service /etc/systemd/system/coreos-borg-maintenance@.service
install_config borg/coreos-borg-maintenance@check.timer /etc/systemd/system/coreos-borg-maintenance@check.timer
install_config borg/coreos-borg-maintenance@compact.timer /etc/systemd/system/coreos-borg-maintenance@compact.timer

sudo systemctl --verbose daemon-reload
sudo systemctl --verbose enable --now coreos-borg-backup.timer coreos-borg-maintenance@compact.timer coreos-borg-maintenance@check.timer

log_done 'CoreOS Borg backups setup complete.'
