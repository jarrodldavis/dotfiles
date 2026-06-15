#!/usr/bin/env zsh
set -euo pipefail

if [ "$(uname -s)" = "Linux" ]; then
    brew bundle dump    --global --force --verbose --no-restart --no-vscode
else
    brew bundle dump    --global --force --verbose
fi

brew bundle install     --global --force --verbose
brew bundle cleanup     --global --force --verbose
