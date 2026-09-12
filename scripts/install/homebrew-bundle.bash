#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Installing system dependencies from Homebrew Bundle...'

if [ -f ~/.Brewfile ]; then
    if [ -n "${DOTFILES_SKIP_MAS:-}" ]; then
        HOMEBREW_BUNDLE_MAS_SKIP="$(grep '^mas' ~/.dotfiles/configs/brew/macos.Brewfile | awk -F'id: ' '{print $2}' | xargs echo)"
        export HOMEBREW_BUNDLE_MAS_SKIP
    fi

    if [ -n "${DOTFILES_REINSTALL:-}" ]; then
        brew bundle install --global --verbose --force
    else
        brew bundle install --global --verbose
    fi
else
    log_warning 'No Brewfile found, skipping Homebrew Bundle installation.'
fi
