#!/bin/sh
set -eu

LOG_TEMPLATE='\033[1;%sm%b\033[0m\033[1;%sm%s\033[0m\n'

if [ -n "${DOTFILES_SKIP_MAS:-}" ]; then
    printf "$LOG_TEMPLATE" 33 '==> ' 39 'Note: Mac App Store apps will not be installed.'
    echo
fi

if [ -n "${DOTFILES_REINSTALL:-}" ]; then
    printf "$LOG_TEMPLATE" 33 '==> ' 39 'Note: Homebrew and system dependencies will be reinstalled.'
    echo
fi

check_sudo() {
    if ! sudo -vn 2>/dev/null; then
        printf '\a'
        printf "$LOG_TEMPLATE" 33 '==> ' 39 'Sudo access is required:'
        sudo -v
    fi
}

BASH_ENV="$(mktemp)"
export BASH_ENV
BREW_SHELLENV="$(mktemp)"
cat <<EOF > "$BASH_ENV"
trap 'export HOMEBREW_PREFIX; env | grep HOMEBREW > $BREW_SHELLENV' EXIT
EOF

if [ -n "${DOTFILES_REINSTALL:-}" ]; then
    if brew --version 1>/dev/null 2>/dev/null; then
        printf "$LOG_TEMPLATE" 31 '--> ' 39 'Uninstalling Homebrew...'
        check_sudo
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
        . "$BREW_SHELLENV"
        check_sudo
        sudo rm -rfv "$HOMEBREW_PREFIX"
    fi
fi

printf "$LOG_TEMPLATE" 35 '--> ' 39 'Installing Homebrew...'
check_sudo
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
. "$BREW_SHELLENV"
eval "$("$HOMEBREW_PREFIX"/bin/brew shellenv)"
brew completions link

unset BASH_ENV

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
mkdir       -v  -p                                                 ~/.config/gh
ln          -v  -sf    ~/.dotfiles/configs/gh/config.yml           ~/.config/gh/config.yml
ln          -v  -sf    ~/.dotfiles/configs/gh/hosts.yml            ~/.config/gh/hosts.yml
ln          -v  -sf    ~/.dotfiles/scripts/dotfiles-pre-commit.sh  ~/.dotfiles/.git/hooks/pre-commit
mkdir       -v  -p                                                 "$(brew --repository)"/Library/Taps/jarrodldavis/homebrew-dotfiles

if [ "$(uname)" = "Linux" ]; then
    if [ -n "${REMOTE_CONTAINERS:-}" ]; then
        # copy gitconfig to avoid picking up dev container credential configuration changes
        cp  -v  -f     ~/.dotfiles/configs/gitconfig               ~/.gitconfig
    else
        ln  -v  -sf    ~/.dotfiles/configs/gitconfig               ~/.gitconfig
    fi

    ln      -v  -sf    ~/.dotfiles/configs/Brewfile-linux          ~/.Brewfile
    ln      -v  -sf    ~/.dotfiles/configs/gitconfig-ssh           ~/.gitconfig-ssh
    ln      -v  -snf   ~/.dotfiles/Formula                         "$(brew --repository)"/Library/Taps/jarrodldavis/homebrew-dotfiles/Formula
elif [ "$(uname)" = "Darwin" ]; then
    ln      -v  -sf    ~/.dotfiles/configs/gitconfig               ~/.gitconfig
    ln      -v  -sf    ~/.dotfiles/configs/Brewfile-macos          ~/.Brewfile
    mkdir   -v  -p                                                 ~/Library/Application\ Support/Code/User
    ln      -v  -sf    ~/.dotfiles/configs/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
    ln      -v  -sf    ~/.dotfiles/configs/vscode/settings.json    ~/Library/Application\ Support/Code/User/settings.json
    mkdir   -v  -p                                                 ~/Library/Containers/net.sonuscape.mouseless/Data/.mouseless/configs
    # hardlink required due to Mouseless sandboxing
    ln      -v  -f     ~/.dotfiles/configs/mouseless/config.yaml   ~/Library/Containers/net.sonuscape.mouseless/Data/.mouseless/configs/config.yaml
    ln      -v  -sf    ~/.dotfiles/configs/gitconfig-macos         ~/.gitconfig-macos
    ln      -v  -sf    ~/.dotfiles/configs/gitconfig-ssh           ~/.gitconfig-ssh
    ln      -v  -sf    ~/.dotfiles/configs/ideavimrc               ~/.ideavimrc
    mkdir   -v  -p                                                 ~/.xinitrc.d
    ln      -v  -sf    ~/.dotfiles/configs/xhost.sh                ~/.xinitrc.d/xhost.sh
    mkdir   -v  -p                                                 ~/Library/LaunchAgents
    ln      -v  -shf   ~/.dotfiles/Formula                         "$(brew --repository)"/Library/Taps/jarrodldavis/homebrew-dotfiles/Formula
fi

if [ -n "${WSL_DISTRO_NAME:-}" ]; then
    WIN_HOME=$(wslpath "$(cmd.exe /C "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')")
    OP_SSH_SIGN="$WIN_HOME/AppData/Local/Microsoft/WindowsApps/op-ssh-sign-wsl.exe"
    ln      -v  -sf    ~/.dotfiles/configs/gitconfig-wsl           ~/.gitconfig-wsl
    check_sudo
    sudo ln -v  -sf    "$OP_SSH_SIGN"                              /usr/local/bin/op-ssh-sign-wsl
fi

if [ -d ~/.oh-my-zsh ]; then
    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Removing Oh My Zsh...'
    # shellcheck disable=SC2016
    command env ZSH="$HOME/.oh-my-zsh" sh -ceu 'yes | head -n1 | sh -eu $ZSH/tools/uninstall.sh'
fi

if command -v conda 1>/dev/null 2>/dev/null; then
    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Initializing Conda for Zsh...'
    ZDOTDIR=~ conda init zsh
fi

printf "$LOG_TEMPLATE" 35 '--> ' 39 'Installing system dependencies from Homebrew Bundle...'

if [ -n "${DOTFILES_SKIP_MAS:-}" ]; then
    HOMEBREW_BUNDLE_MAS_SKIP="$(~/.dotfiles/scripts/list-mas-ids.sh)"
    export HOMEBREW_BUNDLE_MAS_SKIP
fi

if [ -n "${DOTFILES_REINSTALL:-}" ]; then
    brew bundle install --global --verbose --force
else
    brew bundle install --global --verbose
fi

if [ "$(uname)" = "Darwin" ]; then
    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Installing 1Password SSH Agent...'
    ~/.dotfiles/scripts/register-1password-agent.sh

    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Configuring XQuartz...'
    ~/.dotfiles/scripts/configure-xquartz.sh

    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Setting up Git LFS...'
    git lfs install --system --skip-repo
fi

if [ -n "${WSL_DISTRO_NAME:-}" ]; then
    printf "$LOG_TEMPLATE" 35 '--> ' 39 'Configuring default shell...'
    check_sudo
    sudo chsh -s "$(which zsh)" "$(whoami)"
fi

printf "$LOG_TEMPLATE" 32 '--> ' 39 'Dotfiles installation complete!'
