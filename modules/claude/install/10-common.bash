log_substep 'Linking Claude configuration...'
CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
symlink CLAUDE.md "$CLAUDE_CONFIG_DIR/CLAUDE.md"

log_substep 'Installing plugins...'
claude plugin marketplace add mattpocock/skills
claude plugin install mattpocock-skills@mattpocock

claude plugin marketplace add google/elephant-goldfish-model
claude plugin install egm@egm
