check_sudo

log_substep 'Installing CoreOS Borg backup and maintenance services...'

install_executable coreos-borg-backup.bash /usr/local/sbin/coreos-borg-backup
install_config coreos-borg-backup.service /etc/systemd/system/coreos-borg-backup.service
install_config coreos-borg-backup.timer /etc/systemd/system/coreos-borg-backup.timer

install_executable coreos-borg-maintenance.bash /usr/local/sbin/coreos-borg-maintenance
install_config coreos-borg-maintenance@.service /etc/systemd/system/coreos-borg-maintenance@.service
install_config coreos-borg-maintenance@check.timer /etc/systemd/system/coreos-borg-maintenance@check.timer
install_config coreos-borg-maintenance@compact.timer /etc/systemd/system/coreos-borg-maintenance@compact.timer

log_substep 'Enabling CoreOS Borg timers...'
sudo systemctl --verbose daemon-reload
sudo systemctl --verbose enable --now coreos-borg-backup.timer coreos-borg-maintenance@compact.timer coreos-borg-maintenance@check.timer
