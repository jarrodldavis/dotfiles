#!/bin/sh
set -eu

LOG_TEMPLATE='\033[1;%sm%b\033[0m\033[1;%sm%s\033[0m\n'
REINSTALL="${DOTFILES_REINSTALL:-}"

if [ -n "${DOTFILES_SKIP_MAS:-}" ]; then
    printf "$LOG_TEMPLATE" 33 '==> ' 39 'Note: Mac App Store apps will not be installed.'
    echo
fi

if [ -n "$REINSTALL" ]; then
    printf "$LOG_TEMPLATE" 33 '==> ' 39 'Note: Homebrew and system dependencies will be reinstalled.'
    echo
fi

if [ "$(uname)" = "Darwin" ]; then
    if [ "$(uname -m)" = "arm64" ]; then
        HOMEBREW_PREFIX=/opt/homebrew
    else
        HOMEBREW_PREFIX=/usr/local
    fi

    if [ -n "$REINSTALL" ]; then
        printf "$LOG_TEMPLATE" 31 '--> ' 39 'Uninstalling Homebrew...'

        if brew --version 1>/dev/null 2>/dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
        fi

        sudo rm -rf "$HOMEBREW_PREFIX"
    fi

    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Installing Homebrew...'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
elif ! git --version 1>/dev/null 2>/dev/null; then
    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Installing Git...'

    if apt-get --version 1>/dev/null 2>/dev/null; then
        apt-get update
        apt-get install -y git
    else
        echo 'fatal: unsupported package manager'
        exit 1
    fi
fi

printf "$LOG_TEMPLATE" 35 '--> ' 39 'Checking for dotfiles repository...'

if ! git -C ~/.dotfiles status; then
    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Cloning dotfiles repository...'
    git clone https://github.com/jarrodldavis/dotfiles.git ~/.dotfiles
else
    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Updating dotfiles repository...'
    git -C ~/.dotfiles pull
fi

git -C ~/.dotfiles remote set-url --push origin git@github.com:jarrodldavis/dotfiles.git

printf "$LOG_TEMPLATE" 35 '--> ' 39 'Linking dotfiles...'

ln          -v  -sf    ~/.dotfiles/configs/zshenv                  ~/.zshenv
ln          -v  -sf    ~/.dotfiles/configs/gitignore               ~/.gitignore
mkdir       -v  -p                                                 ~/.ssh
ln          -v  -sf    ~/.dotfiles/configs/ssh/allowed_signers     ~/.ssh/allowed_signers

if [ "$(uname)" = "Linux" ] && [ -n "${REMOTE_CONTAINERS:-}" ]; then
    # copy gitconfig to avoid picking up dev container credential configuration changes
    cp      -v  -f     ~/.dotfiles/configs/gitconfig               ~/.gitconfig
    ln      -v  -sf    ~/.dotfiles/configs/gitconfig-ssh           ~/.gitconfig-ssh
elif [ "$(uname)" = "Darwin" ]; then
    ln      -v  -sf    ~/.dotfiles/configs/gitconfig               ~/.gitconfig
    ln      -v  -sf    ~/.dotfiles/configs/brew/Brewfile.full      ~/.Brewfile
    mkdir   -v  -p                                                 ~/Library/Application\ Support/Code/User
    ln      -v  -sf    ~/.dotfiles/configs/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
    ln      -v  -sf    ~/.dotfiles/configs/vscode/settings.json    ~/Library/Application\ Support/Code/User/settings.json
    ln      -v  -sf    ~/.dotfiles/configs/gitconfig-1password     ~/.gitconfig-1password
    ln      -v  -sf    ~/.dotfiles/configs/gitconfig-ssh           ~/.gitconfig-ssh
    ln      -v  -sf    ~/.dotfiles/configs/ideavimrc               ~/.ideavimrc
    mkdir   -v  -p                                                 ~/Library/LaunchAgents
    ln      -v  -sf    ~/.dotfiles/scripts/dotfiles-pre-commit.sh  ~/.dotfiles/.git/hooks/pre-commit
    mkdir   -v  -p                                                 "$(brew --repository)"/Library/Taps/jarrodldavis/homebrew-dotfiles
    ln      -v  -shf   ~/.dotfiles/Formula                         "$(brew --repository)"/Library/Taps/jarrodldavis/homebrew-dotfiles/Formula
fi

if [ "$(uname)" = "Linux" ]; then
    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Installing system dependencies...'

    if apt-get --version 1>/dev/null 2>/dev/null; then
        ~/.dotfiles/scripts/install-github-release-deb.sh sharkdp       bat
        ~/.dotfiles/scripts/install-github-release-deb.sh dandavison    delta   git-delta
    else
        echo 'fatal: unsupported package manager'
        exit 1
    fi
elif [ "$(uname)" = "Darwin" ]; then
    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Installing system dependencies from Homebrew Bundle...'

    if [ -n "${DOTFILES_SKIP_MAS:-}" ]; then
        HOMEBREW_BUNDLE_MAS_SKIP="$(~/.dotfiles/scripts/list-mas-ids.sh)"
        export HOMEBREW_BUNDLE_MAS_SKIP
    fi

    DOTFILES_REINSTALL="$REINSTALL" ~/.dotfiles/scripts/select-homebrew-profiles.sh

    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Installing 1Password SSH Agent...'
    ~/.dotfiles/scripts/register-1password-agent.sh

    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Setting up GitHub CLI...'
    if ! gh auth status; then
        printf '\a'
        gh auth login --git-protocol ssh --hostname github.com --skip-ssh-key --web
    fi

    gh extension install github/gh-copilot
fi

printf "$LOG_TEMPLATE" 32 '--> ' 39 'Dotfiles installation complete!'
