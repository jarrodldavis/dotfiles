#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking Borg backup server helper...'
symlink "$HOME/.dotfiles/modules/borg/backup-server.bash" ~/.local/bin/borg-backup-server
