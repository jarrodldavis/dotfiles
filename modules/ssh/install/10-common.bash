#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking SSH configuration...'
symlink base.sshconfig ~/.ssh/config
symlink config.local.d ~/.ssh/config.local.d
symlink allowed_signers ~/.ssh/allowed_signers
