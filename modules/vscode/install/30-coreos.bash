log_substep 'Installing VSCode agent SDK updater...'
symlink update-agent-sdks.bash ~/.local/bin/update-vscode-agent-sdks
symlink update-agent-sdks.service ~/.config/systemd/user/update-vscode-agent-sdks.service
symlink update-agent-sdks.timer ~/.config/systemd/user/update-vscode-agent-sdks.timer
systemd_enable user update-vscode-agent-sdks.timer

log_substep 'Injecting Bash shell configuration block...'
ensure_source_block "$HOME/.bashrc" rc.coreos.vscode rc.coreos.vscode.bash
