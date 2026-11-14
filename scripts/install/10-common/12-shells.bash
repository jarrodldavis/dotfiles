#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Injecting Zsh configuration blocks...'

ensure_source_block "$HOME/.zshenv"   env     "configs/zsh/env.zsh"
ensure_source_block "$HOME/.zprofile" profile "configs/zsh/profile.zsh"
ensure_source_block "$HOME/.zshrc"    rc      "configs/zsh/rc.zsh"
