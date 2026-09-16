#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Linking dotfiles...'
log_substep 'Linking common dotfiles...'

symlink ../../scripts/maintenance/pre-commit.bash ~/.dotfiles/.git/hooks/pre-commit

# isolate dotfiles-managed gitconfig from machine-specific settings
symlink gitconfigs/base.gitconfig "${XDG_CONFIG_HOME:-$HOME/.config}/git/config"
touch ~/.gitconfig

symlink gitconfigs/ssh.gitconfig

symlink gitignore

symlink gh/config.yml ~/.config/gh/config.yml
# copy hosts config since it can contain auth tokens
if [[ ! -e ~/.config/gh/hosts.yml ]]; then
    copy gh/hosts.yml ~/.config/gh/hosts.yml
fi

symlink ssh/base.sshconfig ~/.ssh/config
symlink ssh/config.local.d
symlink ssh/allowed_signers

symlink brew/brew.env ~/.homebrew/brew.env
