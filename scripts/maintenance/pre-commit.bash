#!/usr/bin/env bash
set -euo pipefail
source ~/.dotfiles/scripts/helpers.bash

~/.dotfiles/scripts/maintenance/update-homebrew-bundle.bash
~/.dotfiles/scripts/maintenance/update-global-gitignore.bash
~/.dotfiles/scripts/maintenance/shellcheck-all.bash

log_done 'Pre-commit maintenance tasks completed!'
