#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking KDE configuration...'

symlink homebrew-env.sh ~/.config/plasma-workspace/env/homebrew.sh
symlink ssh-auth-env.sh ~/.config/plasma-workspace/env/ssh-auth.sh
