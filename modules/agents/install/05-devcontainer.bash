log_substep "Linking dev container state directories for Claude and Codex..."

if [[ ! -d /vscode-state ]]; then
    log_warn "VSCode state directory does not exist"
else
    sudo mkdir -pv /vscode-state/{.claude,.codex}
    sudo chown -v "$(id -u):$(id -g)" /vscode-state/{.claude,.codex}
    ln -sfnTv /vscode-state/.claude ~/.claude
    ln -sfnTv /vscode-state/.codex ~/.codex
fi
