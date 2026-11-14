#!/usr/bin/env bash
set -Eeuo pipefail

##
## -- Helpers
##

if [[ -t 1 && -n ${TERM:-} ]] && tput colors >/dev/null 2>&1; then
    bold="$(tput bold)";
    reset="$(tput sgr0)"

    white="$(tput setaf 7)"
    cyan="$(tput setaf 6)"
    blue="$(tput setaf 4)"
    purple="$(tput setaf 5)"
    green="$(tput setaf 2)"
    yellow="$(tput setaf 3)"
    red="$(tput setaf 1)"
else
    bold=""
    reset=""

    white=""
    cyan=""
    blue=""
    purple=""
    green=""
    yellow=""
    red=""
fi

log() {
    local color="$1"
    local prefix="$2"
    shift 2
    printf '%s%s%s %s%s%s\n' "$bold" "$color" "$prefix" "$white" "$*" "$reset"
}

log_step() {
    log "$purple" "-->" "$@"
}

log_done() {
    log "$green"  "-->" "$@"
}

log_substep() {
    log "$blue" "==>" "$@"
}

log_info() {
    log "$cyan" "==>" "$@"
}

log_success() {
    log "$green"  "==>" "$@"
}

log_warning() {
    log_bell
    log "$yellow" "==>" "$@" >&2
}

log_error() {
    log_bell
    log "$red"    "==>" "$@" >&2
}

log_fatal() {
    log_error "$@"
    print_stack_trace 2 "${BASH_LINENO[0]}"
    exit 1
}

log_bell() {
    printf '\a'
}

check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_warning 'Sudo access is required:'
        sudo -v
    fi
}

format_source_path() {
    local source=$1 resolved

    resolved=$(realpath "$source" 2>/dev/null) || resolved=$source

    if [[ $source == "$resolved" ]]; then
        printf '%s' "$source"
    else
        printf '%s -> %s' "$source" "$resolved"
    fi
}

print_stack_trace() {
    local skip=$1 line=$2
    local i

    printf 'Stack trace:\n' >&2
    for ((i = skip; i < ${#FUNCNAME[@]}; i++)); do
        printf '  %s %s (%s:%s)\n' \
            "$([[ $i -eq $skip ]] && printf 'at' || printf 'called by')" \
            "${FUNCNAME[i]}" \
            "$(format_source_path "${BASH_SOURCE[i]}")" \
            "$line" >&2

        line=${BASH_LINENO[i]}
    done
}

print_error_trace() {
    local status=$1 command=$2
    printf '\n' >&2
    printf 'Error: command failed with exit status %d\n' "$status" >&2
    printf '  Command: %s\n' "$command" >&2
    print_stack_trace 2 "${BASH_LINENO[0]}"
    return "$status"
}

trap 'print_error_trace "$?" "$BASH_COMMAND"' ERR

##
## -- Options and Environment
##

if [[ -n "${DOTFILES_HELPERS_ONLY:-}" ]]; then
    return 0
fi

log_step 'Preparing to install dotfiles...'

case "$(uname)" in
    Darwin)
        log_info 'Detected macOS:'
        sw_vers
        ;;
    Linux)
        log_info 'Detected Linux:'
        cat /etc/os-release
        ;;
    *)
        log_fatal "Unsupported operating system: $(uname)"
        ;;
esac

if [[ -n "${DOTFILES_SKIP_MAS:-}" ]]; then
    log_warning 'Note: Mac App Store apps will not be installed.'
fi

if [[ -n "${DOTFILES_REINSTALL:-}" ]]; then
    log_warning 'Note: Homebrew and system dependencies will be reinstalled.'
fi

##
## -- Homebrew
##

log_step 'Installing Homebrew...'

if [[ -n "${DOTFILES_REINSTALL:-}" ]]; then
    if brew --version 1>/dev/null 2>&1; then
        log_warning 'Uninstalling Homebrew...'
        HOMEBREW_PREFIX="$(brew --prefix)"
        check_sudo
        NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
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
} | NONINTERACTIVE=1 bash

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

export BASH_ENV="$HOME/.dotfiles/scripts/env.bash"
bash ~/.dotfiles/scripts/install/run-install-scripts.bash

log_done 'Dotfiles installation complete!'
