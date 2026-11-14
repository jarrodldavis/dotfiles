log_substep 'Linking Steam configuration...'
symlink power-profile-watch.py ~/.local/bin/steam-power-profile-watch
symlink power-profile-watch.service ~/.config/systemd/user/steam-power-profile-watch.service
symlink 90-pressure-vessel.conf ~/.config/environment.d/90-pressure-vessel.conf

log_substep 'Configuring shader background processing threads...'
mkdir -pv ~/.local/share/Steam
cat > ~/.local/share/Steam/steam_dev.cfg <<EOF
@ShaderBackgroundProcessingThreads $(nproc)
unShaderBackgroundProcessingThreads $(nproc)
EOF

log_substep 'Enabling automatic Steam performance profile service...'
systemctl --user --verbose daemon-reload
systemctl --user --verbose enable --now steam-power-profile-watch.service
