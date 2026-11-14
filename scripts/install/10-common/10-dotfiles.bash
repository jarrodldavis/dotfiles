#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking common dotfiles...'

symlink gh/config.yml ~/.config/gh/config.yml
# copy hosts config since it can contain auth tokens
if [[ ! -e ~/.config/gh/hosts.yml ]]; then
    copy gh/hosts.yml ~/.config/gh/hosts.yml
fi

symlink gh/extensions/gh-stack-pull ~/.local/share/gh/extensions/gh-stack-pull

symlink codex/AGENTS.md
