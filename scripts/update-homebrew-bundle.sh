#!/usr/bin/env zsh
set -euo pipefail

brew bundle dump    --global --force --verbose
brew bundle install --global --force --verbose
brew bundle cleanup --global --force --verbose
