#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

symlink "$HOME/.dotfiles/modules/nvidia/70-nvidia.conf" ~/.config/environment.d/70-nvidia.conf
