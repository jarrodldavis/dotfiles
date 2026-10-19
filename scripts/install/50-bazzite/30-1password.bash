#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring 1Password...'
check_sudo

log_substep 'Copying Firefox integration config into Flatpak directory...'
dest_dir="$HOME/.var/app/org.mozilla.firefox/.mozilla/native-messaging-hosts"
src_dir="$HOME/.mozilla/native-messaging-hosts"
wrapper_script="1PasswordWrapper.sh"
wrapper_config="com.1password.1password.json"

copy "$src_dir/$wrapper_script" "$dest_dir/$wrapper_script"
jq --arg path "$dest_dir/$wrapper_script" '.path = $path' "$src_dir/$wrapper_config" > "$dest_dir/$wrapper_config"
cat "$dest_dir/$wrapper_config"

log_substep 'Allowlisting XDG Native Messaging Proxy...'
install_config 1password/custom_allowed_browsers /etc/1password/custom_allowed_browsers

log_substep 'Configuring Yama LSM...'
# https://support.1password.com/linux-ptrace-scope-issue/
echo "kernel.yama.ptrace_scope=1" | sudo tee /etc/sysctl.d/99-1password-ptrace-scope.conf
sudo sysctl --system
