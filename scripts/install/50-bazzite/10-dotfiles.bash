#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking Bazzite dotfiles...'

symlink kde/homebrew-env.sh ~/.config/plasma-workspace/env/homebrew.sh
symlink kde/ssh-auth-env.sh ~/.config/plasma-workspace/env/ssh-auth.sh

symlink nvidia/70-nvidia.conf ~/.config/environment.d/70-nvidia.conf
