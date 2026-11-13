#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Removing Git SSH configuration in Codespaces...'

rm -vf ~/.gitconfigs/ssh.gitconfig
