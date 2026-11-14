#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking macOS dotfiles...'

symlink mouseless/config.yaml ~/Library/Application\ Support/Mouseless/configs/config.yaml
