#!/usr/bin/env bash
set -euo pipefail
source ~/.dotfiles/scripts/helpers.bash

# shellcheck disable=SC2016
log_step 'Configuring desktop applications with Homebrew $PATH...'

mkdir -pv ~/.config/environment.d
cat > ~/.config/environment.d/60-homebrew.conf <<EOF
PATH=$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:\$PATH
EOF
