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
    _log "$green"  "-->" "$@"
}

log_warning() {
    _log "$yellow" "==>" "$@" >&2
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
        log_substep 'Detected macOS:'
        sw_vers
        ;;
    Linux)
        log_substep 'Detected Linux:'
        cat /etc/os-release
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

log_substep 'Linking dotfiles repository hooks...'
symlink ../../scripts/dotfiles-pre-commit.sh ~/.dotfiles/.git/hooks/pre-commit

log_substep 'Linking common dotfiles...'

# isolate dotfiles-managed gitconfig from machine-specific settings
symlink gitconfigs/base.gitconfig "${XDG_CONFIG_HOME:-$HOME/.config}/git/config"
touch ~/.gitconfig

symlink gitignore

symlink gh/config.yml ~/.config/gh/config.yml
# copy hosts config since it can contain auth tokens
copy gh/hosts.yml ~/.config/gh/hosts.yml

symlink ssh/base.sshconfig ~/.ssh/config
symlink ssh/config.local.d
symlink ssh/allowed_signers

symlink brew/brew.env ~/.homebrew/brew.env

if [ "$(uname)" = "Darwin" ]; then
    log_substep 'Linking macOS dotfiles...'
    symlink gitconfigs/macos.gitconfig
    symlink gitconfigs/ssh.gitconfig

    symlink ssh/macos.sshconfig ~/.ssh/config.d/macos

    symlink brew/macos.Brewfile ~/.Brewfile

    symlink vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
    symlink vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

    symlink mouseless/config.yaml ~/Library/Application\ Support/Mouseless/configs/config.yaml

    symlink nut/nut.conf /opt/homebrew/etc/nut/nut.conf
    symlink nut/ups.conf /opt/homebrew/etc/nut/ups.conf
    symlink nut/upsd.conf /opt/homebrew/etc/nut/upsd.conf
    if ! [ -f /opt/homebrew/etc/nut/upsd.users ]; then
        copy nut/upsd.users /opt/homebrew/etc/nut/upsd.users
    fi
else
    log_substep 'Linking Linux dotfiles...'

    if [ "${CODESPACES:-}" != "true" ]; then
        symlink gitconfigs/ssh.gitconfig
    fi

    if [ "${ID:-}" = "fedora" ] && [ "${VARIANT_ID:-}" = "coreos" ]; then
        log_substep 'Linking Fedora CoreOS dotfiles...'
        symlink brew/coreos.Brewfile ~/.Brewfile
    fi

    if [ "${ID:-}" = "bazzite" ]; then
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
    fi

    if [ "${REMOTE_CONTAINERS:-}" = "true" ]; then
        log_substep 'Linking VS Code Remote Containers dotfiles...'
        symlink brew/devcontainer.Brewfile ~/.Brewfile
    fi
fi

##
## -- Homebrew Bundle
##
log_step 'Installing system dependencies from Homebrew Bundle...'

if [ -f ~/.Brewfile ]; then
    if [ -n "${DOTFILES_SKIP_MAS:-}" ]; then
        HOMEBREW_BUNDLE_MAS_SKIP="$(~/.dotfiles/scripts/list-mas-ids.sh)"
        export HOMEBREW_BUNDLE_MAS_SKIP
    fi

    if [ -n "${DOTFILES_REINSTALL:-}" ]; then
        brew bundle install --global --verbose --force
    else
        brew bundle install --global --verbose
    fi
else
    log_warning 'No Brewfile found, skipping Homebrew Bundle installation.'
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
else
    if [ "${ID:-}" = "fedora" ] && [ "${VARIANT_ID:-}" = "coreos" ]; then
        log_substep 'Configuring systemd...'
        systemctl --user enable --now podman.socket
    fi

    if [ "${ID:-}" = "bazzite" ]; then
        log_substep 'Configuring Snapper...'
        check_sudo
        ~/.dotfiles/scripts/configure-snapper.sh

        log_substep 'Configuring Vorta System Inventory...'
        check_sudo
        ~/.dotfiles/scripts/configure-system-inventory.sh

        log_substep 'Configuring Lenovo Legion GPU RGB...'
        check_sudo
        ~/.dotfiles/scripts/configure-gpu-rgb.sh

        log_substep 'Configuring systemd...'
        systemctl --user daemon-reload
        systemctl --user restart steam-download-inhibit.service

        log_substep "Configuring desktop applications with Homebrew \$PATH..."
        mkdir -pv ~/.config/environment.d
        cat > ~/.config/environment.d/60-homebrew.conf <<EOF
PATH=$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:\$PATH
EOF
    fi
fi

log_done 'Dotfiles installation complete!'
