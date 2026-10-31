#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Injecting Bazzite shell configuration blocks...'

ensure_source_block "$HOME/.bashrc" rc.bazzite "configs/bash/rc.bazzite.bash"
