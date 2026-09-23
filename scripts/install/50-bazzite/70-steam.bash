#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Configuring Steam...'

mkdir -pv ~/.local/share/Steam
cat > ~/.local/share/Steam/steam_dev.cfg <<EOF
@ShaderBackgroundProcessingThreads $(nproc)
unShaderBackgroundProcessingThreads $(nproc)
EOF
