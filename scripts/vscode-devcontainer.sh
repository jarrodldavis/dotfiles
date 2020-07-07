#!/usr/bin/env bash

set -e

# only sudo if necessary, as sudo may not be pre-installed
function sudo_if() {
    if [ "$EUID" != 0 ]; then
        sudo -n "$@"
    else
        "$@"
    fi
}

function common_setup() {
    export DEBIAN_FRONTEND=noninteractive

    # Install common packages, add non-root user, install ZSH
    local USERNAME
    USERNAME="$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)" # use existing user, if it exists
    USERNAME="${USERNAME:-vscode}" # fallback to `vscode` user

    local INSTALLER_SCRIPT
    if type apt-get > /dev/null 2>&1; then
        # for some odd reason the Oryx images used by Visual Studio Codespaces has
        # Debian 10 (buster) sources even though the image is Debian 9 (stretch)
        if [ -f "/etc/apt/sources.list.d/buster.list" ]; then
            sudo_if rm /etc/apt/sources.list.d/buster.list
        fi

        INSTALLER_SCRIPT="common-debian.sh"
    elif type yum  > /dev/null 2>&1; then
        INSTALLER_SCRIPT="common-redhat.sh"
    elif type apk > /dev/null 2>&1; then
        INSTALLER_SCRIPT="common-alpine.sh"
    else
        echo "Unsupported Linux distribution"
        exit 1
    fi

    local INSTALLER="$HOME/.dotfiles/scripts/vscode-dev-containers/script-library/$INSTALLER_SCRIPT"
    sudo_if apt-get update
    sudo_if "$INSTALLER" true "$USERNAME"

    # Install Live Share prerequisites
    ~/.dotfiles/scripts/live-share/scripts/linux-prereqs.sh

    # Install man-db for manpages
    # Install python for dotbot
    # Install x11-apps to test X11 forwarding
    # Install gnupg and pinentry-curses for git commit signing
    sudo_if apt-get -y install man-db python x11-apps gnupg pinentry-curses

    unset DEBIAN_FRONTEND
}

common_setup

# Install Starship prompt
~/.dotfiles/scripts/starship/install/install.sh --yes

# Install additional tools
function install_from_github() {
    local OWNER="$1"
    local REPO="$2"
    local FILE="$3"
    local BIN_REL="$4"

    local RELEASE_URL="https://api.github.com/repos/$OWNER/$REPO/releases/latest"

    case "$FILE" in
        "__TARBALL__")
            local JQ_SCRIPT=".tarball_url"
            ;;
        *)
            local JQ_SCRIPT=".assets[].browser_download_url | select(. | contains(\"$FILE\"))"
            ;;
    esac

    local DOWNLOAD_URL
    DOWNLOAD_URL=$(curl -s "$RELEASE_URL" | jq -r "$JQ_SCRIPT")

    local INSTALL_DIR="/opt/github.com/$OWNER/$REPO/"
    sudo_if mkdir -pv "$INSTALL_DIR"
    curl -fsSL "$DOWNLOAD_URL" | sudo tar -xzv -C "$INSTALL_DIR" --strip-components=1

    local BIN_ABS="$INSTALL_DIR/$BIN_REL"
    sudo_if ln -sfv "$BIN_ABS" /usr/local/bin
}

install_from_github "sharkdp" "bat" "-x86_64-unknown-linux-gnu.tar.gz" "bat"
install_from_github "github" "hub" "hub-linux-amd64" "bin/hub"
install_from_github "so-fancy" "diff-so-fancy" "__TARBALL__" "diff-so-fancy"

# Force ZSH as default shell
echo "exec zsh" > ~/.bashrc
