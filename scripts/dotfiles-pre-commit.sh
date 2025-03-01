#!/bin/zsh
set -euo pipefail

LOG_TEMPLATE='\033[1;%sm%b\033[0m\033[1;%sm%s\033[0m\n'

printf "$LOG_TEMPLATE" 35 '--> ' 39 'Updating Homebrew Bundle...'

~/.dotfiles/scripts/update-homebrew-bundle.sh

UNSAVED=0

if [ -s configs/brew/Brewfile.new ]; then
    printf "$LOG_TEMPLATE" 31 '--> ' 39 'Newly installed system dependencies found.'
    printf "$LOG_TEMPLATE" 31 '==> ' 39 'Review "configs/brew/Brewfile.new" and move entries to the appropriate profile-specific Brewfile.'
    UNSAVED=1
fi

if [ -s configs/brew/Brewfile.old ]; then
    printf "$LOG_TEMPLATE" 31 '--> ' 39 'Newly removed system dependencies found.'
    printf "$LOG_TEMPLATE" 31 '==> ' 39 'Review "configs/brew/Brewfile.old" and remove entries from the appropriate profile-specific Brewfile.'
    UNSAVED=1
fi

if [ $UNSAVED -eq 0 ]; then
    printf "$LOG_TEMPLATE" 32 '==> ' 39 'No unsaved changes to system dependencies found.'
else
    exit 1
fi

printf "$LOG_TEMPLATE" 35 '--> ' 39 'Validating scripts...'
~/.dotfiles/scripts/shellcheck-all.sh
