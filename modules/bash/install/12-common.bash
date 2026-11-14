#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Configuring common Bash settings...'

symlink inputrc ~/.inputrc

ensure_source_block "$HOME/.bash_profile" profile profile.bash
ensure_source_block "$HOME/.bashrc" rc rc.bash
