#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Configuring common Bash settings...'

symlink "$HOME/.dotfiles/modules/bash/inputrc" ~/.inputrc

ensure_source_block "$HOME/.bash_profile" profile "modules/bash/profile.bash"
ensure_source_block "$HOME/.bashrc" rc "modules/bash/rc.bash"
