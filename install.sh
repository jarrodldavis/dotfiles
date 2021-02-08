#!/bin/sh

set -e

# region Initialize internal variables

unset INSTALLER_RUN_CONTINUE_ON_ERROR
unset INSTALLER_RUN_QUIET
unset PACKAGE_MANAGER
unset IN_DOCKER
unset USER_ID
unset USER_NAME
unset SUDO_INSTALLED
unset NON_ROOT_USER_ID
unset NON_ROOT_USER_NAME

INSTALLER_RUN_CONTINUE_ON_ERROR=''
INSTALLER_RUN_QUIET=''
PACKAGE_MANAGER=''
IN_DOCKER=''
USER_ID=''
USER_NAME=''
SUDO_INSTALLED=''
NON_ROOT_USER_ID=''
NON_ROOT_USER_NAME=''

if [ "$(command -v sudo)" ]; then
    SUDO_INSTALLED='1'
fi

# Unset $PATH to ensure all external commands go through the run function.
# However, the uname/id/sw_vers commands are used to retrieve values,
# and thus can't be used through the run function.

if [ "$(command -v uname)" ]; then
    # shellcheck disable=SC2139
    alias uname="$(command -v uname)"
fi

if [ "$(command -v id)" ]; then
    # shellcheck disable=SC2139
    alias id="$(command -v id)"
fi

if [ "$(command -v sw_vers)" ]; then
    # shellcheck disable=SC2139
    alias sw_vers="$(command -v sw_vers)"
fi

EXTERNAL_PATH="$PATH"

unset PATH
# shellcheck disable=SC2123
PATH=''

# endregion

# region Log helper functions

format_color() {
    prefix_color="$1"
    prefix_text="$2"
    main_color="$3"
    main_text="$4"

    printf '\033[1;%sm%b\033[0m\033[1;%sm%s\033[0m\n' "$prefix_color" "$prefix_text" "$main_color" "$main_text"

    unset prefix_color
    unset prefix_text
    unset main_color
    unset main_text
}

 COLOR_UNBOLD="0"
    COLOR_RED="31"
  COLOR_GREEN="32"
 COLOR_YELLOW="33"
   COLOR_BLUE="34"
COLOR_MAGENTA="35"
   COLOR_CYAN="36"
COLOR_DEFAULT="39"

PREFIX_NEWSTEP="=>> "
PREFIX_SUBSTEP="--> "
    PREFIX_RUN="==> "
   PREFIX_INFO="### "
PREFIX_SUBINFO=''
PREFIX_SUCCESS=">>> "
PREFIX_WARNING="=!= "
  PREFIX_ERROR="=!= "

log_step() {
    format_color "$COLOR_MAGENTA" "$PREFIX_NEWSTEP" "$COLOR_DEFAULT" "$1"
}

log_substep() {
    format_color "$COLOR_CYAN"    "$PREFIX_SUBSTEP" "$COLOR_DEFAULT" "$1"
}

log_run() {
    format_color "$COLOR_BLUE"    "$PREFIX_RUN"     "$COLOR_DEFAULT" "$1"
}

log_info() {
    format_color "$COLOR_BLUE"    "$PREFIX_INFO"    "$COLOR_DEFAULT" "$1"
}

log_subinfo() {
    format_color "$COLOR_DEFAULT" "$PREFIX_SUBINFO" "$COLOR_UNBOLD"  "$1"
}

log_warn() {
    format_color "$COLOR_YELLOW"  "$PREFIX_WARNING" "$COLOR_YELLOW"  "$1"
}

log_success() {
    format_color "$COLOR_GREEN"   "$PREFIX_SUCCESS" "$COLOR_GREEN"   "$1"
}

log_error() {
    format_color "$COLOR_RED"     "$PREFIX_ERROR"   "$COLOR_RED"     "$1"
}

exit_success() {
    log_success "$1"
    exit 0
}

exit_error() {
    log_error "$1"
    exit 1
}

# endregion

# region External command helpers

run_core() {
    if [ -z "$1" ]; then
        exit_error "Cannot run empty command."
    fi

    input="$*"

    if [ -z "$INSTALLER_RUN_QUIET" ] || [ -n "$INSTALLER_EXTRA_VERBOSE" ]; then
        log_run "$*"
    fi

    if [ "$1" = "$PACKAGE_MANAGER" ]; then
        if [ "$USER_ID" = '0' ]; then
            set -- "$@"
        elif [ "$SUDO_INSTALLED" = '1' ]; then
            set -- sudo -n -- "$@"
        else
            exit_error "Cannot run package manager command as non-root user without sudo."
        fi
    elif [ -z "$NON_ROOT_USER_NAME" ] || [ "$NON_ROOT_USER_NAME" = "$USER_NAME" ]; then
        set -- "$@"
    elif [ "$SUDO_INSTALLED" = '1' ]; then
        # use env to ensure $PATH is preserved (since -E intentionally ignores $PATH)
        set -- sudo -Enu "$NON_ROOT_USER_NAME" -- env PATH="$EXTERNAL_PATH" "$@"
    else
        log_error "Cannot run command since a non-root user was found but sudo is not installed."
        log_info "To ensure correct file permissions, non-package manager commands are run as \"$NON_ROOT_USER_NAME\" using sudo."
        exit 1
    fi

    if [ -n "$INSTALLER_EXTRA_VERBOSE" ] && [ "$*" != "$input" ]; then
        log_substep "$*"
    fi

    unset input

    export PATH="$EXTERNAL_PATH" 

    if ! "$@" ; then
        if [ -n "$INSTALLER_RUN_CONTINUE_ON_ERROR" ]; then
            return 1
        else
            exit_error "Failed to run command: $*"
        fi
    fi

    unset PATH
    # shellcheck disable=SC2123
    PATH=''
}

# Some POSIX shell implementations don't scope environment variables to a single command when
# using the `ENV=value command` syntax, so use functions to accurately scope run options.

run() {
    unset INSTALLER_RUN_QUIET
    unset INSTALLER_RUN_CONTINUE_ON_ERROR
    run_core "$@"
    unset INSTALLER_RUN_QUIET
    unset INSTALLER_RUN_CONTINUE_ON_ERROR
}

run_quiet() {
    INSTALLER_RUN_QUIET=1
    unset INSTALLER_RUN_CONTINUE_ON_ERROR
    run_core "$@"
    unset INSTALLER_RUN_QUIET
    unset INSTALLER_RUN_CONTINUE_ON_ERROR
}

run_and_continue() {
    unset INSTALLER_RUN_QUIET
    INSTALLER_RUN_CONTINUE_ON_ERROR=1
    run_core "$@"
    result="$?"
    unset INSTALLER_RUN_QUIET
    unset INSTALLER_RUN_CONTINUE_ON_ERROR

    if [ "$result" = '0' ]; then
        unset result
        return 0
    else
        unset result
        return 1
    fi
}

run_quiet_and_continue() {
    INSTALLER_RUN_QUIET=1
    INSTALLER_RUN_CONTINUE_ON_ERROR=1
    run_core "$@"
    result="$?"
    unset INSTALLER_RUN_QUIET
    unset INSTALLER_RUN_CONTINUE_ON_ERROR

    if [ "$result" = '0' ]; then
        unset result
        return 0
    else
        unset result
        return 1
    fi
}

# endregion

# region Detect operating system

if [ "$(command -v uname)" ]; then
    OS_FAMILY="$(uname)"
else
    exit_error 'Could not detect operating system. Only Linux and macOS are supported.'
fi

if [ "$OS_FAMILY" = 'Darwin' ]; then
    if [ "$(command -v sw_vers)" ]; then
        log_info "Running dotfiles installer on $(sw_vers -productName) $(sw_vers -productVersion)."
    else
        exit_error 'Unsupported Darwin operating system. Only macOS is supported.'
    fi
elif [ "$OS_FAMILY" = 'Linux' ]; then
    # os-release provides distro-specific info, like $PRETTY_NAME and $ANSI_COLORS, for human-friendly output
    if [ -f '/etc/os-release' ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
    elif [ -f '/usr/lib/os-release' ]; then
        # shellcheck disable=SC1091
        . /usr/lib/os-release
    fi

    # Fallback to Linux kernel info if no distro-specific info is available (or is missing $PRETTY_NAME)
    PRETTY_NAME="${PRETTY_NAME:-"$(uname -rs)"}"

    # Color text using distro-specific colors (if available), but keep text bolded
    PRETTY_NAME="$(printf '\033[%sm\033[1m%s\033[0m' "${ANSI_COLOR:-0}" "$PRETTY_NAME")"

    log_info "Running dotfiles installer on $PRETTY_NAME."

    if [ "$ID" = 'alpine' ]; then
        # Homebrew doesn't like to use a system-installed Ruby on newer Alpine releases because it is too new, and
        # Portable Ruby requires glibc, which isn't available on MUSL systems line Alpine Linux.
        # Additionally, even if the system-installed Ruby is an appropriate version, the glibc requirement becomes a
        # problem (e.g. "cannot find your system's linker") when installing some packages.
        exit_error "${NAME-"$ID"} is not yet supported."
    fi

    PATH="$EXTERNAL_PATH"

    if [ "$(command -v apk)" ]; then
        PACKAGE_MANAGER='apk'
        log_info 'Using apk as the system package manager.'
    elif [ "$(command -v apt-get)" ]; then
        PACKAGE_MANAGER='apt-get'
        log_info 'Using apt-get as the system package manager.'
        run export DEBIAN_FRONTEND='noninteractive'
    elif [ "$(command -v pacman)" ]; then
        PACKAGE_MANAGER='pacman'
        log_info 'Using pacman as the system package manager.'
    elif [ "$(command -v yum)" ]; then
        PACKAGE_MANAGER='yum'
        log_info 'Using yum as the system package manager.'
    else
        exit_error 'No supported package manager found. One of apk, apt-get, pacman, or yum must be available.'
    fi

    unset PATH
    # shellcheck disable=SC2123
    PATH=''

    if [ -f '/.dockerenv' ]; then
        log_info 'Docker environment detected.'
        IN_DOCKER=1
    fi
else
    exit_error "Unsupported operating system family \"$OS_FAMILY\"."
fi

# endregion

# region Check installation permissions for current user

log_step "Checking installation permissions for current user..."

# shellcheck disable=SC2039
if [ -n "$UID" ] && [ -n "$USER" ]; then
    USER_ID="$UID"
    USER_NAME="$USER"
elif [ "$(command -v id)" ]; then
    USER_ID="$(id -u)"
    USER_NAME="$(id -un)"
else
    log_warn "Could not determine current user; assuming current user is root."
    USER_ID="0"
    USER_NAME="root"
fi

log_info "Current user:"
log_subinfo "login: $USER_NAME"
log_subinfo "   ID: $USER_ID"
log_subinfo " home: $HOME"

if [ "$USER_ID" = '0' ]; then
    if [ "$IN_DOCKER" != '1' ]; then
        exit_error 'Refusing to continue installation for root user in non-Docker environment.'
    fi
else
    if [ "$SUDO_INSTALLED" != '1' ]; then
        exit_error 'Cannot continue installation for non-root user without sudo installed.'
    fi

    log_substep 'Priming sudo session for non-interactive installation...'

    if ! run_and_continue sudo -v ; then
        exit_error 'Cannot continue installation for non-root user who is not a sudoer.'
    fi

    # sudo keep-alive
    log_substep 'Enabling keep-alive for sudo session...'
    while true; do
        run_quiet_and_continue sudo -vn
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
    jobs -l
fi

# endregion

# region Linux system packages

if [ "$OS_FAMILY" = 'Linux' ]; then

    # region Update system packages

    log_step 'Updating system packages...'
    case "$PACKAGE_MANAGER" in
        'apk')      run apk update;        run apk upgrade ;;
        'apt-get')  run apt-get -y update; run apt-get -y upgrade ;;
        'pacman')   run pacman --noconfirm -Syu ;;
        'yum')      run yum -y update;     run yum -y upgrade ;;
    esac

    # endregion

    # region Install prerequisites

    log_step 'Installing prerequisites...'

    set -f # disable globbing for safe word splitting
    extra_pkgs='bash coreutils curl file git grep procps sudo'

    # shellcheck disable=SC2086
    case "$PACKAGE_MANAGER" in
        'apk')      run apk add build-base shadow $extra_pkgs ruby ruby-bigdecimal ruby-etc ruby-fiddle ruby-irb ruby-json ruby-test-unit ;;
        'apt-get')  run apt-get -y install build-essential passwd $extra_pkgs ;;
        'pacman')   run pacman --noconfirm -S base-devel util-linux $extra_pkgs ;;
        'yum')
            run yum -y swap coreutils-single coreutils
            run yum -y groupinstall 'Development Tools';
            run yum -y install $extra_pkgs

            # libxcrypt-compat is required for Fedora installs, and is only available on Fedora
            log_substep "Checking for additional required packages..."
            if run_and_continue yum -y info libxcrypt-compat ; then
                run yum -y install libxcrypt-compat
            fi

            # chsh used to be provided by util-linux, but moved to util-linux-user in newer OS versions
            if run_and_continue yum -y info util-linux-user ; then
                run yum -y install util-linux-user
            else
                run yum -y install util-linux
            fi
            ;;
    esac

    unset extra_pkgs

    set +f # re-enable globbing

    SUDO_INSTALLED='1'

    # endregion

fi

# endregion

# region Looking for appropriate installer user

if [ "$USER_ID" = '0' ]; then
    log_step 'Looking for non-root Visual Studio Code Development Container user...'

    if ! [ -f "/etc/passwd" ]; then
        exit_error "Local user database could not be found."
    fi

    # $ID sourced from os-release
    case "$ID" in
        "centos") MIN_USER_ID="1000" ;;
               *) MIN_USER_ID="500"  ;;
    esac

    MAX_USER_ID="2000"

    # /etc/passwd format
    # name:password:id:group_id:full_name_or_comment:home:shell
    while IFS=':' read -r user_name _ user_id _ _ user_home user_shell; do
        # skip system users
        case "$user_shell" in *nologin* | *shutdown* | *halt*) continue ;; esac

        # ensure user ID is an integer
        if ! printf '%d' "$user_id" >/dev/null 2>&1 ; then
            log_warn "Ignoring junk user ID:"
            log_subinfo "$user_id"
        fi

        # skip system users
        if [ "$user_id" -lt "$MIN_USER_ID" ] || [ "$user_id" -gt "$MAX_USER_ID" ]; then
            continue
        fi

        # skip non-sudoers
        if ! run_and_continue sudo -lnU "$user_name" sudo ; then
            log_warn "Ignoring non-sudoer:"
            log_subinfo "login: $user_name"
            log_subinfo "   ID: $user_id"
            log_subinfo " home: $user_home"
            continue
        fi

        NON_ROOT_USER_ID="$user_id"
        NON_ROOT_USER_NAME="$user_name"

        # set $HOME so that tilde expansion works correctly later
        HOME="$user_home"

        log_info "Found non-root user:"
        log_subinfo "login: $NON_ROOT_USER_NAME"
        log_subinfo "   ID: $NON_ROOT_USER_ID"
        log_subinfo " home: $HOME"

        break
    done < /etc/passwd

    unset MIN_USER_ID MAX_USER_ID user_name user_id user_home user_shell

    if [ -z "$NON_ROOT_USER_ID" ]; then
        log_warn "Could not find non-root user."
    fi
else
    NON_ROOT_USER_ID="$USER_ID"
    NON_ROOT_USER_NAME="$USER_NAME"
fi

# endregion

# region Initialize dotfiles directory

log_step 'Initializing dotfiles repository...'

clone_standard_path() {
    dir="$HOME/ghq/github.com/jarrodldavis/dotfiles"

    if [ -d "$dir" ]; then
        log_info 'Using existing standard local dotfiles directory:'
        log_subinfo "$dir"
    else
        REPO='https://github.com/jarrodldavis/dotfiles.git'
        log_substep 'Cloning dotfiles repository to standard local dotfiles path:'
        run git clone --verbose "$REPO" "$dir"
    fi   
}

if [ "$0" = 'sh' ] || [ "$0" = '/bin/sh' ]; then
    log_info "Detected automatic bootstrapping."
    clone_standard_path
elif [ -f "$0" ]; then
    log_substep "Determining absolute directory of installer script:"
    log_subinfo "$0"

    # https://github.com/dylanaraps/pure-sh-bible#get-the-directory-name-of-a-file-path
    dir=${0:-.}
    dir=${dir%%"${dir##*[!/]}"}
    [ "${dir##*/*}" ] && dir=.
    dir=${dir%/*}
    dir=${dir%%"${dir##*[!/]}"}

    if [ -z "$dir" ]; then
        exit_error "Unable to determine directory of installer script."
    elif ! [ -d "$dir" ] || ! abs_dir="$(cd "$dir" && pwd)" 2>/dev/null ; then
        log_info "Found installer script in non-accessible directory:"
        log_subinfo "$dir"
        exit_error "Cannot continue installation in non-accessible directory."
    elif ! run_and_continue git -C "$abs_dir" status ; then
        log_warn "Found installer script in non-repository directory:"
        log_subinfo "$abs_dir"
        clone_standard_path
    else
        dir="$abs_dir"
        unset abs_dir
        log_info 'Using existing dotfiles directory:'
        log_subinfo "$dir"
    fi
else
    exit_error "Unable to determine source of installer script."
fi

run cd "$dir"
unset dir
unset -f clone_standard_path

log_substep 'Initializing git submodules...'
run git submodule update --init --recursive

# endregion

# region Link dotfiles

log_step 'Linking dotfiles...'

link() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        exit_error "Source and destination are required for linking a dotfile."
    fi

    source="$PWD/$1"
    destination="$2"

    if [ -f "$source" ] || [ -d "$source" ]; then
        log_subinfo "> $destination -> $source"

        case "$destination" in
            "$HOME"*)
                if [ -s "$destination" ]; then
                    run_quiet rm "$destination"
                fi
                run_quiet ln -sf "$source" "$destination"
                ;;

            *)
                if [ -s "$destination" ]; then
                    run_quiet sudo rm "$destination"
                fi
                run_quiet sudo ln -sf "$source" "$destination"
                ;;
        esac
    else
        exit_error "Non-existent source: $destination -> $source"
    fi

    unset source
    unset destination
}

makedir() {
    if [ -z "$1" ]; then
        exit_error "Destination is required for creating a dotfile directory."
    fi

    if ! [ -d "$1" ]; then
        log_subinfo "+ $1"

        if [ -f "$1" ]; then
            run_quiet rm "$1"
        fi

        run_quiet mkdir -p "$1"
    fi
}


## TODO: Clean symbolic links

link scripts/pinentry-auto.sh       /usr/local/bin/pinentry-auto
link profile                        ~/.profile
link profile                        ~/.bashrc
link zshrc                          ~/.zshrc
link scripts/zsh                    ~/.zshfunctions
link gitconfig                      ~/.gitconfig
link gitignore                      ~/.gitignore
makedir                             ~/.ssh/
link ssh-config                     ~/.ssh/config
makedir                             ~/.gnupg/
link gpg.conf                       ~/.gnupg/gpg.conf
link gpg-agent.conf                 ~/.gnupg/gpg-agent.conf
link Brewfile                       ~/.Brewfile
link starship.toml                  ~/.starship.toml
link vimrc                          ~/.vimrc

if [ "$OS_FAMILY" = 'Darwin' ]; then
    link ideavimrc                                      ~/.ideavimrc
    makedir                                             ~/Library/LaunchAgents/
    link launch-agents/com.jarrodldavis.setenv.plist    ~/Library/LaunchAgents/com.jarrodldavis.setenv.plist
    makedir                                             ~/Library/Application\ Support/Code/User/
    link vscode/settings.json                           ~/Library/Application\ Support/Code/User/settings.json
    link vscode/keybindings.json                        ~/Library/Application\ Support/Code/User/keybindings.json
    link vscode/snippets                                ~/Library/Application\ Support/Code/User/snippets
    makedir                                             /Applications/Google\ Chrome.app/Contents/MacOS/
    link scripts/open-chromium.sh                       /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome
fi

unset -f link makedir

log_substep 'Setting correct permissions for GnuPG directory...'
run chmod u=rwx,go= ~/.gnupg
run chmod u=rwx,go= ~/.gnupg/* # TODO: only set +x for subdirectories

log_substep 'Setting correct permissions for SSH directory...'
run chmod u=rwx,go= ~/.ssh
run chmod u=rw,go= ~/.ssh/*

# endregion

# region Install Hombrew

log_step 'Installing Homebrew...'

# CI environment variable is used to run installer non-interactively

if [ "$NON_ROOT_USER_NAME" ]; then
    run env CI=true homebrew/install.sh
elif [ "$USER_ID" = '0' ]; then
    log_warn 'Overriding effective user ID to force root Homebrew installation.'
    run env CI=true EUID=1 homebrew/install.sh
fi

# endregion

# region Skip Homebrew Bundle

if [ "$IN_DOCKER" = 1 ]; then
    if [ -z "$INSTALLER_CONTINUE_HOMEBREW_BUNDLE" ]; then
        log_warn 'Skipping Homebrew Bundle and subsequent installation steps.'
        log_info 'Set INSTALLER_CONTINUE_HOMEBREW_BUNDLE=1 to continue with Homebrew Bundle.'
        exit_success 'Dotfiles installation complete'
    else
        log_warn 'Continuing with Homebrew Bundle; this may take a while.'
    fi
else
    if [ -n "$INSTALLER_SKIP_HOMEBREW_BUNDLE" ]; then
        log_warn 'Skipping Homebrew Bundle and subsequent installation steps.'
        log_info 'Unset INSTALLER_SKIP_HOMEBREW_BUNDLE to continue with Homebrew Bundle.'
        exit_success 'Dotfiles installation complete'
    fi
fi

# endregion

# region Install packages

log_step 'Installing packages from Homebrew Bundle...'

if [ "$OS_FAMILY" = 'Linux' ]; then
    HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

EXTERNAL_PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$EXTERNAL_PATH"

if [ "$OS_FAMILY" = 'Linux' ]; then
    run export HOMEBREW_BUNDLE_TAP_SKIP='heroku/brew homebrew/cask-versions'
    run export HOMEBREW_BUNDLE_BREW_SKIP='act pinentry-mac heroku/brew/heroku'

    # https://github.com/Homebrew/linuxbrew-core/issues/21601
    run export HOMEBREW_PATCHELF_RB_WRITE=1

    # Vim and Zsh use Perl but the formula for Perl has problems in the postinstall step.
    # On some Linux distros (CentOS, Fedora, and Arch Linux), installing XML::Parser fails
    # because the Homebrew-installed Perl's CPAN can't find the Homebrew-installed expat.
    log_substep 'Installing Perl...'
    run sh -c 'EDITOR="sed -i -e /XML::/d" brew edit perl'
    run brew install perl

    log_substep 'Continuing with Homebrew Bundle...'
    run brew bundle --global --verbose

    # Unlink formulae that are likely to conflict with versions explicitly
    # installed in a development container image.
    log_substep 'Unlinking workspace-conflicting formulae...'

    # use globs while in the Cellar to target versioned formulae (e.g. `python@3.9`)
    run cd "$HOMEBREW_PREFIX/Cellar"
    for formula in java* node* perl* python* ruby*; do
        if [ -d "$formula" ]; then
            run brew unlink "$formula"
        fi
    done

    run cd "$OLDPWD"
else
    run brew bundle --global --verbose
fi

# endregion

# region Import GPG public keys

log_step 'Importing GPG public keys...'

import_gpg_key() {
    run sh -c "curl https://github.com/$1.gpg | gpg --import-options keep-ownertrust --import"
}

import_gpg_key web-flow
import_gpg_key jarrodldavis
run gpg --list-keys

# endregion

# region Install Vim plugins

log_step 'Installing Vim plugins...'

while IFS='/' read -r plugin_owner plugin_repo; do
    plugin_remote="https://github.com/${plugin_owner}/${plugin_repo}.git"
    plugin_path="$HOME/.vim/pack/${plugin_owner}/start/${plugin_repo}"

    if [ -d "$plugin_path" ]; then
        run git -C "$plugin_path" pull
    else
        run git clone "$plugin_remote" "$plugin_path"
    fi
done < ./Vimfile

unset plugin_owner plugin_repo plugin_remote plugin_path

# endregion

# region Install Visual Studio Code extensions

if [ "$OS_FAMILY" = 'Darwin' ]; then
    log_step 'Installing Visual Studio Code extensions...'

    vscode_args='--force'
    while IFS='' read -r extension; do
        vscode_args="$vscode_args --install-extension $extension"
    done < ./Codefile

    # shellcheck disable=2086
    run code $vscode_args
    # shellcheck disable=2086
    run code-insiders $vscode_args

    unset vscode_args
fi

# endregion

# region Set default shell

log_step 'Updating default shell to Homebrew Zsh...'

ZSH_BIN="$HOMEBREW_PREFIX/bin/zsh"

if [ -f '/etc/shells' ]; then
    while IFS='' read -r valid_shell; do
        if [ "$valid_shell" = "$ZSH_BIN" ]; then
            zsh_already_added='1'
            break
        fi
    done < /etc/shells

    if [ "$zsh_already_added" != '1' ]; then
        log_substep 'Updating valid login shells:'
        log_subinfo "$ZSH_BIN >> /etc/shells"
        run sudo -n -- bash -c "echo '$ZSH_BIN' >> /etc/shells"
    fi

    unset valid_shell zsh_already_added
else
    log_warn 'Could not find valid shell list; assuming any shell binary path is valid for chsh.'
fi

SHELL_USER="${NON_ROOT_USER_NAME:-"$USER_NAME"}"
log_substep "Setting default shell for \"$SHELL_USER\"..."
run sudo -n -- chsh -s "$ZSH_BIN" "$SHELL_USER"

# endregion

exit_success 'Dotfiles installation complete.'
