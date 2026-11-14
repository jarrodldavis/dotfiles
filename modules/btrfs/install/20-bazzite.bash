log_substep 'Configuring maintenance...'
check_sudo
install_config btrfsmaintenance.conf /etc/sysconfig/btrfsmaintenance
sudo systemctl restart btrfsmaintenance-refresh.service

log_substep 'Configuring monitor...'
symlink btrfs-space-monitor.bash ~/.local/bin/btrfs-space-monitor
symlink btrfs-space-monitor.service ~/.config/systemd/user/btrfs-space-monitor.service
symlink btrfs-space-monitor.timer ~/.config/systemd/user/btrfs-space-monitor.timer
systemctl --verbose --user daemon-reload
systemctl --verbose --user enable btrfs-space-monitor.timer
