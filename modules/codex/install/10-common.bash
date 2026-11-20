log_substep 'Linking Codex configuration...'
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
symlink AGENTS.md "$CODEX_HOME/AGENTS.md"

log_substep 'Installing plugins...'
codex plugin marketplace add mattpocock/skills
codex plugin add mattpocock-skills@mattpocock

codex plugin marketplace add google/elephant-goldfish-model
codex plugin add egm@egm
