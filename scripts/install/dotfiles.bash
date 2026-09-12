#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Linking dotfiles...'

_ensure_parent_dir() {
    local dir="$1"
    mkdir -vp "$dir"
}

_get_link_paths() {
    case $# in
        1)
            from="$HOME/.dotfiles/configs/$1"
            to="$HOME/.$1"
            ;;
        2)
            case $1 in
                /*|./*|../*) from=$1 ;;
                *)           from="$HOME/.dotfiles/configs/$1" ;;
            esac
            to=$2
            ;;
        *)
            # shellcheck disable=SC2016
            printf 'error: invalid %s usage: expected `%s NAME [DESTINATION]`\n' "$helper" "$helper" >&2
            return 2
            ;;
    esac

    case "$from" in
        /*) from_check="$from" ;;
        *)  from_check="$(dirname "$to")/$from" ;;
    esac

    if ! [ -e "$from_check" ]; then
        printf 'error: source file does not exist: %s\n' "$from_check" >&2
        return 1
    fi
}

symlink() {
    local helper="symlink" from to
    _get_link_paths "$@"
    _ensure_parent_dir "$(dirname "$to")"
    ln -vnfs "$from" "$to"
}

hardlink() {
    local helper="hardlink" from to
    _get_link_paths "$@"
    _ensure_parent_dir "$(dirname "$to")"
    ln -vnf "$from" "$to"
}

copy() {
    local helper="copy" from to
    _get_link_paths "$@"
    _ensure_parent_dir "$(dirname "$to")"
    cp -vf "$from" "$to"
}

dotfiles_common() {
    log_substep 'Linking common dotfiles...'
    symlink ../../scripts/maintenance/pre-commit.bash ~/.dotfiles/.git/hooks/pre-commit

    # isolate dotfiles-managed gitconfig from machine-specific settings
    symlink gitconfigs/base.gitconfig "${XDG_CONFIG_HOME:-$HOME/.config}/git/config"
    touch ~/.gitconfig

    symlink gitconfigs/ssh.gitconfig

    symlink gitignore

    symlink gh/config.yml ~/.config/gh/config.yml
    # copy hosts config since it can contain auth tokens
    if [ ! -e ~/.config/gh/hosts.yml ]; then
        copy gh/hosts.yml ~/.config/gh/hosts.yml
    fi

    symlink ssh/base.sshconfig ~/.ssh/config
    symlink ssh/config.local.d
    symlink ssh/allowed_signers

    symlink brew/brew.env ~/.homebrew/brew.env
}

dotfiles_macos() {
    log_substep 'Linking macOS dotfiles...'
    symlink gitconfigs/macos.gitconfig

    symlink ssh/macos.sshconfig ~/.ssh/config.d/macos

    symlink brew/macos.Brewfile ~/.Brewfile

    symlink vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
    symlink vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

    symlink mouseless/config.yaml ~/Library/Application\ Support/Mouseless/configs/config.yaml
}

dotfiles_linux() {
    log_substep 'Linking Linux dotfiles...'
}

dotfiles_coreos() {
    log_substep 'Linking Fedora CoreOS dotfiles...'
    symlink brew/coreos.Brewfile ~/.Brewfile
}

dotfiles_bazzite() {
    log_substep 'Linking Bazzite dotfiles...'
    symlink gitconfigs/bazzite.gitconfig

    symlink ssh/bazzite.sshconfig ~/.ssh/config.d/bazzite

    symlink brew/bazzite.Brewfile ~/.Brewfile

    symlink vscode/settings.json ~/.config/Code/User/settings.json
    symlink vscode/keybindings.json ~/.config/Code/User/keybindings.json

    symlink systemd/steam-download-inhibit.py ~/.local/bin/steam-download-inhibit
    symlink systemd/steam-download-inhibit.service ~/.config/systemd/user/steam-download-inhibit.service
    symlink systemd/steam-update-wake.service ~/.config/systemd/user/steam-update-wake.service

    symlink vorta/update-system-inventory.bash ~/.local/bin/update-system-inventory
}

dotfiles_devcontainer() {
    log_substep 'Linking VS Code Remote Containers dotfiles...'
    symlink brew/devcontainer.Brewfile ~/.Brewfile
}

dotfiles_codespaces() {
    log_substep 'Linking GitHub Codespaces dotfiles...'
    rm -vf ~/.gitconfigs/ssh.gitconfig
}

dotfiles() {
    local targets=("$@")
    for target in "${targets[@]}"; do
        "dotfiles_$target"
    done
}

resolve_install_targets dotfiles
