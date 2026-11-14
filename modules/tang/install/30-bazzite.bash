symlink tang.container ~/.config/containers/systemd/tang.container
ensure_dir ~/.local/share/tang

log_substep 'Configuring systemd service...'
systemctl --user --verbose daemon-reload
systemctl --user --verbose restart tang.service

log_substep 'Enabling user session linger...'
loginctl enable-linger "$USER"
loginctl show-user "$USER"
