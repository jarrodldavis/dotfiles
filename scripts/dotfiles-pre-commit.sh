#!/usr/bin/env zsh
set -euo pipefail

LOG_TEMPLATE='\033[1;%sm%b\033[0m\033[1;%sm%s\033[0m\n'

printf "$LOG_TEMPLATE" 35 '--> ' 39 'Updating Homebrew Bundle...'
~/.dotfiles/scripts/update-homebrew-bundle.sh

printf "$LOG_TEMPLATE" 35 '--> ' 39 'Updating global gitignore...'
~/.dotfiles/scripts/update-global-gitignore.sh

printf "$LOG_TEMPLATE" 35 '--> ' 39 'Validating scripts...'
~/.dotfiles/scripts/shellcheck-all.sh
