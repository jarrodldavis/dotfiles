#!/bin/zsh
set -euo pipefail

echo '==> Fixing directory permissions...'
sudo chown -v "$(id -un)":"$(id -gn)" .. . .git

echo '==> Done!'
