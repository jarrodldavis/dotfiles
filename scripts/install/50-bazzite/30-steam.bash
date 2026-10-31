#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Configuring shader background processing threads...'
mkdir -pv ~/.local/share/Steam
cat > ~/.local/share/Steam/steam_dev.cfg <<EOF
@ShaderBackgroundProcessingThreads $(nproc)
unShaderBackgroundProcessingThreads $(nproc)
EOF

log_substep 'Enabling automatic Steam performance profile service...'
systemctl --user --verbose daemon-reload
systemctl --user --verbose enable --now steam-power-profile-watch.service
