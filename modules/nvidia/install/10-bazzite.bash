#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

symlink 70-nvidia.conf ~/.config/environment.d/70-nvidia.conf
