#!/usr/bin/env bash

# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

export BASH_ENV="$HOME/.dotfiles/scripts/env.bash"
bash ~/.dotfiles/modules/homebrew/update-homebrew-bundle.bash
bash ~/.dotfiles/modules/git/update-global-gitignore.bash
bash ~/.dotfiles/scripts/maintenance/shellcheck-all.bash

log_done 'Pre-commit maintenance tasks completed!'
