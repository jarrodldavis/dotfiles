#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Injecting Zsh configuration blocks...'

ensure_source_block "$HOME/.zshenv"   env     env.zsh
ensure_source_block "$HOME/.zprofile" profile profile.zsh
ensure_source_block "$HOME/.zshrc"    rc      rc.zsh
