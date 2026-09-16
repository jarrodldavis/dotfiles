#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking VS Code Remote Containers dotfiles...'

symlink brew/devcontainer.Brewfile ~/.Brewfile
