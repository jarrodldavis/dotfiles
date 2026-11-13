#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

module_dir="$HOME/.dotfiles/modules/ssh"

log_substep 'Linking SSH configuration...'
symlink "$module_dir/base.sshconfig" ~/.ssh/config
symlink "$module_dir/config.local.d" ~/.ssh/config.local.d
symlink "$module_dir/allowed_signers" ~/.ssh/allowed_signers
