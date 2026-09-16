#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking Fedora CoreOS dotfiles...'

symlink brew/coreos.Brewfile ~/.Brewfile

# workaround for Homebrew's poor support for symlinked `/home` directories
mkdir -pv "$(brew --prefix)/lib/docker/cli-plugins"
