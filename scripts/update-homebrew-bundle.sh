#!/bin/zsh
set -euo pipefail

brew bundle dump    --global --force
brew bundle install --global --cleanup
