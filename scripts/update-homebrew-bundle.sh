#!/bin/zsh
set -euo pipefail

if [ "$(uname -s)" = "Linux" ]; then
    brew bundle dump    --global --force --no-restart --no-vscode
else
    brew bundle dump    --global --force
fi

brew bundle install     --global --cleanup
