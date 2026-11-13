#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

if [[ -f ~/.Brewfile ]]; then
    if [[ -n "${DOTFILES_SKIP_MAS:-}" ]]; then
        log_substep "Collecting MAS apps to skip..."
        HOMEBREW_BUNDLE_MAS_SKIP="$(grep '^mas' ~/.Brewfile | awk -F'id: ' '{print $2}' | xargs echo)"
        export HOMEBREW_BUNDLE_MAS_SKIP
    fi

    if [[ -n "${DOTFILES_REINSTALL:-}" ]]; then
        log_substep "Reinstalling system dependencies from Homebrew Bundle..."
        brew bundle install --global --verbose --force
    else
        log_substep "Installing system dependencies from Homebrew Bundle..."
        brew bundle install --global --verbose
    fi
else
    log_warning 'No Brewfile found, skipping Homebrew Bundle installation.'
fi
