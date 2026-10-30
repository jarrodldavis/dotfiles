#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Configuring Homebrew Bash as default shell...'

BREW_BASH="$(brew --prefix)/bin/bash"
if ! grep -Fxq "$BREW_BASH" /etc/shells; then
    check_sudo
    echo "$BREW_BASH" | sudo tee -a /etc/shells
fi

CURRENT_SHELL="$(dscl . -read ~/ UserShell | awk '{print $2}')"
if [[ "$CURRENT_SHELL" != "$BREW_BASH" ]]; then
    chsh -s "$BREW_BASH"
else
    log_info "Homebrew Bash is already the default shell."
fi
