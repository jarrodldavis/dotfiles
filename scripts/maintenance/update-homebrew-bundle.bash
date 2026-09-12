#!/usr/bin/env bash
set -euo pipefail
source ~/.dotfiles/scripts/helpers.bash

log_step 'Updating Homebrew Bundle...'

brew bundle dump    --global --force --verbose
brew bundle install --global --force --verbose
brew bundle cleanup --global --force --verbose
