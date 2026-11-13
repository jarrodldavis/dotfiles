#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

symlink "$HOME/.dotfiles/modules/ssh/macos.sshconfig" ~/.ssh/config.d/macos
