#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking KDE configuration...'

symlink "$HOME/.dotfiles/modules/kde/homebrew-env.sh" ~/.config/plasma-workspace/env/homebrew.sh
symlink "$HOME/.dotfiles/modules/kde/ssh-auth-env.sh" ~/.config/plasma-workspace/env/ssh-auth.sh
