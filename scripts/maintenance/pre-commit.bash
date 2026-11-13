#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

~/.dotfiles/modules/homebrew/update-homebrew-bundle.bash
~/.dotfiles/modules/git/update-global-gitignore.bash
~/.dotfiles/scripts/maintenance/shellcheck-all.bash

log_done 'Pre-commit maintenance tasks completed!'
