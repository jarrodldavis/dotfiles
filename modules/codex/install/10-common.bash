#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking Codex configuration...'

symlink "$HOME/.dotfiles/modules/codex/AGENTS.md" ~/.codex/AGENTS.md
