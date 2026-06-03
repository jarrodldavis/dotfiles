#!/usr/bin/env zsh
set -euo pipefail

echo '==> Fixing directory permissions...'
sudo chown -v "$(id -un)":"$(id -gn)" .. . .git

echo '==> Adding additional git safe directory...'
git config --global --add safe.directory ~/.dotfiles

echo '==> Done!'
