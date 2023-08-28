#!/bin/zsh
set -euo pipefail

brew bundle dump    --global --force
echo '{}' > ~/.dotfiles/configs/Brewfile.lock.json
brew bundle install --global --cleanup
