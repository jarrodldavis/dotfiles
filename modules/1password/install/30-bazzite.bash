check_sudo

log_substep 'Configuring Yama LSM...'
# https://support.1password.com/linux-ptrace-scope-issue/
echo "kernel.yama.ptrace_scope=1" | sudo tee /etc/sysctl.d/99-1password-ptrace-scope.conf
sudo sysctl --system
