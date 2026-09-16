#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking GitHub Codespaces dotfiles...'

rm -vf ~/.gitconfigs/ssh.gitconfig
