#!/bin/bash
set -euo pipefail

##
## -- Helpers
##

if [[ -t 1 && -n ${TERM:-} ]] && tput colors >/dev/null 2>&1; then
    bold="$(tput bold)";
    reset="$(tput sgr0)"

    white="$(tput setaf 7)"
    blue="$(tput setaf 4)"
    purple="$(tput setaf 5)"
    green="$(tput setaf 2)"
    yellow="$(tput setaf 3)"
    red="$(tput setaf 1)"
else
    bold=""
    reset=""

    white=""
    blue=""
    purple=""
    green=""
    yellow=""
    red=""
fi

_log() {
    local color="$1"
    local prefix="$2"
    shift 2
    printf '%s%s%s %s%s%s\n' "$bold" "$color" "$prefix" "$white" "$*" "$reset"
}

log_step() {
    _log "$blue" "-->" "$@"
}

log_substep()  {
    _log "$purple" "==>" "$@"
}

log_done() {
    _log "$green"  "==>" "$@"
}

log_warning() {
    _log "$yellow" "-->" "$@" >&2
}

log_error()  {
    _log "$red"    "==>" "$@" >&2
}

log_bell() {
    printf '\a'
}

check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_bell
        log_warning 'Sudo access is required:'
        sudo -v
    fi
}

##
## -- Options and Environment
##
log_step 'Preparing to install dotfiles...'

case "$(uname)" in
    Darwin)
        log_substep 'Detected macOS.'
        ;;
    Linux)
        log_substep 'Detected Linux.'
        ;;
    *)
        log_error "Unsupported operating system: $(uname)"
        exit 1
        ;;
esac

if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi

if [ -n "${DOTFILES_SKIP_MAS:-}" ]; then
    log_warning 'Note: Mac App Store apps will not be installed.'
fi

if [ -n "${DOTFILES_REINSTALL:-}" ]; then
    log_warning 'Note: Homebrew and system dependencies will be reinstalled.'
fi

##
## -- Homebrew
##
log_step 'Installing Homebrew...'

if [ -n "${DOTFILES_REINSTALL:-}" ]; then
    if brew --version 1>/dev/null 2>/dev/null; then
        log_warning 'Uninstalling Homebrew...'
        HOMEBREW_PREFIX="$(brew --prefix)"
        check_sudo
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
        check_sudo
        sudo rm -rfv "$HOMEBREW_PREFIX"
    fi

    log_substep 'Reinstalling Homebrew...'
fi

check_sudo

BREW_SHELLENV="$(mktemp)"

{
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
    cat <<EOF
export HOMEBREW_PREFIX
env | grep '^HOMEBREW' > "$BREW_SHELLENV"
EOF
} | NONINTERACTIVE=1 /bin/bash

. "$BREW_SHELLENV"
eval "$("$HOMEBREW_PREFIX"/bin/brew shellenv)"
brew completions link

##
## -- Dotfiles Repository
##
log_step 'Checking for dotfiles repository...'

if ! git -C ~/.dotfiles status; then
    log_substep 'Cloning dotfiles repository...'
    git clone https://github.com/jarrodldavis/dotfiles.git ~/.dotfiles
else
    log_substep 'Updating dotfiles repository...'
    git -C ~/.dotfiles pull
fi

git -C ~/.dotfiles remote set-url --push origin git@github.com:jarrodldavis/dotfiles.git

##
## -- Linking Dotfiles
##
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
                /*) from=$1 ;;
                *)  from="$HOME/.dotfiles/$1" ;;
            esac
            to=$2
            ;;
        *)
            printf 'usage: %s NAME [DESTINATION]\n' "$0" >&2
            return 2
            ;;
    esac
}

symlink() {
    _get_link_paths "$@"
    _ensure_parent_dir "$(dirname "$to")"
    ln -vnfs "$from" "$to"
}

hardlink() {
    _get_link_paths "$@"
    _ensure_parent_dir "$(dirname "$to")"
    ln -vnf "$from" "$to"
}

copy() {
    _get_link_paths "$@"
    _ensure_parent_dir "$(dirname "$to")"
    cp -vf "$from" "$to"
}

log_substep 'Linking dotfiles repository hooks...'
symlink scripts/dotfiles-pre-commit.sh ~/.dotfiles/.git/hooks/pre-commit

log_substep 'Linking common dotfiles...'
symlink gitconfig
symlink gitignore
symlink gitconfigs/github-origin
symlink gitconfigs/github-upstream

symlink gh/config.yml
symlink gh/hosts.yml

symlink ssh/config
symlink ssh/config.local.d
symlink ssh/config.d
symlink ssh/allowed_signers

symlink configs/brew.env ~/.homebrew/brew.env

if [ "$(uname)" = "Darwin" ]; then
    log_substep 'Linking macOS dotfiles...'
    symlink gitconfigs/macos
    symlink gitconfigs/ssh

    symlink configs/ssh/config-macos ~/.ssh/config.d/macos

    symlink configs/Brewfile-macos ~/.Brewfile

    symlink configs/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
    symlink configs/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

    symlink configs/mouseless/config.yaml ~/Library/Application\ Support/Mouseless/configs/config.yaml

    symlink configs/nut/nut.conf /opt/homebrew/etc/nut/nut.conf
    symlink configs/nut/ups.conf /opt/homebrew/etc/nut/ups.conf
    symlink configs/nut/upsd.conf /opt/homebrew/etc/nut/upsd.conf
    if ! [ -f /opt/homebrew/etc/nut/upsd.users ]; then
        copy configs/nut/upsd.users /opt/homebrew/etc/nut/upsd.users
    fi
else
    log_substep 'Linking Linux dotfiles...'

    if [ "${CODESPACES:-}" != "true" ]; then
        symlink gitconfigs/ssh
    fi

    if [ "${ID:-}" = "fedora" ] && [ "${VARIANT_ID:-}" = "coreos" ]; then
        log_substep 'Linking Fedora CoreOS dotfiles...'
        symlink /usr/bin/podman ~/.local/bin/docker # force vscode devcontainers to use podman
        symlink configs/Brewfile-coreos ~/.Brewfile
    fi

    if [ "${ID:-}" = "bazzite" ]; then
        log_substep 'Linking Bazzite dotfiles...'
        symlink gitconfigs/bazzite
        symlink configs/ssh/config-bazzite ~/.ssh/config.d/bazzite
        symlink configs/Brewfile-bazzite ~/.Brewfile
    fi
fi

##
## -- Homebrew Bundle
##
log_step 'Installing system dependencies from Homebrew Bundle...'

if [ -n "${DOTFILES_SKIP_MAS:-}" ]; then
    HOMEBREW_BUNDLE_MAS_SKIP="$(~/.dotfiles/scripts/list-mas-ids.sh)"
    export HOMEBREW_BUNDLE_MAS_SKIP
fi

if [ -n "${DOTFILES_REINSTALL:-}" ]; then
    brew bundle install --global --verbose --force
else
    brew bundle install --global --verbose
fi

##
## -- Finalize Configurations
##
log_step 'Finalizing configurations...'

log_substep 'Configuring Shells...'
~/.dotfiles/scripts/configure-shells.sh

if [ "$(uname)" = "Darwin" ]; then
    log_substep 'Installing 1Password SSH Agent...'
    ~/.dotfiles/scripts/register-1password-agent.sh

    log_substep 'Configuring NUT...'
    ~/.dotfiles/scripts/configure-nut.sh

    log_substep 'Setting up Git LFS...'
    git lfs install --system --skip-repo
fi

log_done 'Dotfiles installation complete!'
