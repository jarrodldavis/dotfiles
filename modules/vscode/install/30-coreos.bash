log_substep 'Installing VSCode agent SDK updater...'
symlink update-agent-sdks.bash ~/.local/bin/update-vscode-agent-sdks
symlink update-agent-sdks.service ~/.config/systemd/user/update-vscode-agent-sdks.service
symlink update-agent-sdks.timer ~/.config/systemd/user/update-vscode-agent-sdks.timer
systemd_enable user update-vscode-agent-sdks.timer

log_substep 'Injecting Bash shell configuration block...'
ensure_source_block "$HOME/.bashrc" rc.coreos.vscode rc.coreos.vscode.bash

log_substep 'Fixing Claude Code Auto Mode...'
settings="$HOME/.claude/settings.json"
key="CLAUDE_CODE_AUTO_MODE_SERVER"

mkdir -p "$(dirname "$settings")"
[ -s "$settings" ] || echo '{}' > "$settings"

if jq -e --arg k "$key" '.env? | has($k)?' "$settings" >/dev/null 2>&1; then
  echo "$key already set in $settings: $(jq -r --arg k "$key" '.env[$k]' "$settings")"
  exit 0
fi

cp "$settings" "$settings.bak"
tmp="$(mktemp "$settings.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
jq --arg k "$key" '.env = ((.env // {}) + {($k): "0"})' "$settings" > "$tmp"
mv "$tmp" "$settings"
echo "Added $key=0 to $settings (backup at $settings.bak)"
