#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking Steam configuration...'
module_dir="$HOME/.dotfiles/modules/steam"
symlink "$module_dir/power-profile-watch.py" ~/.local/bin/steam-power-profile-watch
symlink "$module_dir/power-profile-watch.service" ~/.config/systemd/user/steam-power-profile-watch.service
symlink "$module_dir/90-pressure-vessel.conf" ~/.config/environment.d/90-pressure-vessel.conf

log_substep 'Configuring shader background processing threads...'
mkdir -pv ~/.local/share/Steam
cat > ~/.local/share/Steam/steam_dev.cfg <<EOF
@ShaderBackgroundProcessingThreads $(nproc)
unShaderBackgroundProcessingThreads $(nproc)
EOF

log_substep 'Enabling automatic Steam performance profile service...'
systemctl --user --verbose daemon-reload
systemctl --user --verbose enable --now steam-power-profile-watch.service
