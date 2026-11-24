log_substep 'Configuring maintenance...'
check_sudo
install_config btrfsmaintenance.conf /etc/sysconfig/btrfsmaintenance
systemd_restart system btrfsmaintenance-refresh.service

log_substep 'Configuring monitor...'
symlink btrfs-space-monitor.bash ~/.local/bin/btrfs-space-monitor
symlink btrfs-space-monitor.service ~/.config/systemd/user/btrfs-space-monitor.service
symlink btrfs-space-monitor.timer ~/.config/systemd/user/btrfs-space-monitor.timer
systemd_enable user btrfs-space-monitor.timer
