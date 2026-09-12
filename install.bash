#!/usr/bin/env bash
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

log_done() {
    _log "$green"  "-->" "$@"
}

log_substep()  {
    _log "$purple" "==>" "$@"
}

log_success() {
    _log "$green"  "==>" "$@"
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

resolve_install_targets() {
    local func="$1"
    local -a targets=(common)

    if [ "$(uname)" = "Darwin" ]; then
        targets+=(macos)
    else
        if [ -f /etc/os-release ]; then
            # shellcheck source=/dev/null
            . /etc/os-release
        fi

        targets+=(linux)

        if [ "${ID:-}" = "fedora" ] && [ "${VARIANT_ID:-}" = "coreos" ]; then
            targets+=(coreos)
        fi

        if [ "${ID:-}" = "bazzite" ]; then
            targets+=(bazzite)
        fi

        if [ "${REMOTE_CONTAINERS:-}" = "true" ]; then
            targets+=(devcontainer)
        fi

        if [ "${CODESPACES:-}" = "true" ]; then
            targets+=(codespaces)
        fi
    fi

    "$func" "${targets[@]}"
}

##
## -- Options and Environment
##

if [ -n "${DOTFILES_HELPERS_ONLY:-}" ]; then
    return 0
fi

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

log_substep 'Using installation targets:'
resolve_install_targets echo

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

# shellcheck source=/dev/null
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
## -- Main Installers
##
~/.dotfiles/scripts/install/dotfiles.bash
~/.dotfiles/scripts/install/homebrew-bundle.bash
~/.dotfiles/scripts/install/finalize.bash

log_done 'Dotfiles installation complete!'
