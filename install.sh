#!/bin/sh
set -eu

LOG_TEMPLATE='\033[1;%sm%b\033[0m\033[1;%sm%s\033[0m\n'

if [ "$(uname)" = "Darwin" ]; then
    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Installing Homebrew...'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
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

printf "$LOG_TEMPLATE" 35 '--> ' 39 'Linking dotfiles...'

ln          -v  -sf    ~/.dotfiles/configs/zshrc                   ~/.zshrc
ln          -v  -sf    ~/.dotfiles/configs/gitconfig               ~/.gitconfig
ln          -v  -sf    ~/.dotfiles/configs/gitignore               ~/.gitignore
mkdir       -v  -p                                                 ~/.ssh
ln          -v  -sf    ~/.dotfiles/configs/ssh/allowed_signers     ~/.ssh/allowed_signers

if [ "$(uname)" = "Darwin" ]; then
    ln      -v  -sf    ~/.dotfiles/configs/Brewfile                ~/.Brewfile
    ln      -v  -sf    ~/.dotfiles/configs/Brewfile.lock.json      ~/.Brewfile.lock.json
    mkdir   -v  -p                                                 ~/Library/Application\ Support/Code/User
    ln      -v  -sf    ~/.dotfiles/configs/vscode/settings.json    ~/Library/Application\ Support/Code/User/settings.json
    ln      -v  -sf    ~/.dotfiles/configs/gitconfig-1password     ~/.gitconfig-1password
    mkdir   -v  -p                                                 ~/Library/LaunchAgents

    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Installing system dependencies from Homebrew Bundle...'

    if [ -n "${DOTFILES_SKIP_MAS:-}" ]; then
        HOMEBREW_BUNDLE_MAS_SKIP="$(~/.dotfiles/scripts/list-mas-ids.sh)"
        export HOMEBREW_BUNDLE_MAS_SKIP
    fi

    brew bundle install --global --verbose

    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Installing 1Password SSH Agent...'
    ~/.dotfiles/scripts/register-1password-agent.sh
fi

printf "$LOG_TEMPLATE" 32 '--> ' 39 'Dotfiles installation complete!'
