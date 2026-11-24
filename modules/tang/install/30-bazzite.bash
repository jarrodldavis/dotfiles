symlink tang.container ~/.config/containers/systemd/tang.container
ensure_dir ~/.local/share/tang

log_substep 'Configuring systemd service...'
systemd_reload user
systemd_restart user tang.service

log_substep 'Enabling user session linger...'
loginctl enable-linger "$USER"
loginctl show-user "$USER"
