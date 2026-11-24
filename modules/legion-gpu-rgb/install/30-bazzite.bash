log_substep "Configuring Lenovo Legion GPU RGB services..."
check_sudo

install_executable off.sh /usr/local/sbin/legion-gpu-rgb-off
install_config off-boot.service /etc/systemd/system/legion-gpu-rgb-off-boot.service
install_config off-resume.service /etc/systemd/system/legion-gpu-rgb-off-resume.service

systemd_enable system legion-gpu-rgb-off-boot.service legion-gpu-rgb-off-resume.service
