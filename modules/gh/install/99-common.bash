symlink config.yml ~/.config/gh/config.yml
# copy hosts config since it can contain auth tokens
if [[ ! -e ~/.config/gh/hosts.yml ]]; then
    copy hosts.yml ~/.config/gh/hosts.yml
fi

if ! command -v gh >/dev/null 2>&1; then
    log_warning 'GitHub CLI is not installed.'
    exit 0
fi

log_info 'GitHub CLI Authentication status:'
gh auth status || true

log_substep 'Installing GitHub CLI extensions...'

for extension in "$module_dir"/extensions/*; do
    symlink "$extension" "$HOME/.local/share/gh/extensions/$(basename "$extension")"
done

gh extension install jarrodldavis/gh-cd
gh extension install github/gh-stack
gh extension upgrade --all

log_substep 'Installing GitHub CLI skills...'
agents=("claude-code" "codex" "github-copilot")
for agent in "${agents[@]}"; do
    gh skill install --all --scope user --force --agent "$agent" github/gh-stack
done
gh skill update --force --all
