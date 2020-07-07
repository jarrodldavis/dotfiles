#!/usr/bin/env bash

set -e

# Configure apt and install packages
if ! command -v sudo &> /dev/null
then
    if [ "$UID" != 1 ]; then
        echo "You are not root and sudo is not installed. This script requires superuser permissions"
        exit 1
    else
        apt-get -y install sudo
    fi
fi

shopt -s expand_aliases
alias sudo="sudo -n"

sudo apt-get update
export DEBIAN_FRONTEND=noninteractive

# Install man-db for manpages
# Install curl and ca-certificates to download setup scripts
# Install python for dotbot
# Install x11-apps to test X11 forwarding
sudo apt-get -y install man-db curl ca-certificates python x11-apps

# Install common packages, add non-root user, install ZSH
curl -fsSL https://raw.githubusercontent.com/microsoft/vscode-dev-containers/v0.127.0/script-library/common-debian.sh | sudo bash

# Install Live Share prerequisites
curl -fsSL https://raw.githubusercontent.com/MicrosoftDocs/live-share/master/scripts/linux-prereqs.sh | sudo bash

# Install starship prompt
curl -fsSL https://starship.rs/install.sh | sudo bash -s -- --yes

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

    local DOWNLOAD_URL="$(curl -s $RELEASE_URL | jq -r "$JQ_SCRIPT")"

    local INSTALL_DIR="/opt/github.com/$OWNER/$REPO/"
    sudo mkdir -pv "$INSTALL_DIR"
    curl -fsSL $DOWNLOAD_URL | sudo tar -xzv -C "$INSTALL_DIR" --strip-components=1

    local BIN_ABS="$INSTALL_DIR/$BIN_REL"
    sudo ln -sfv "$BIN_ABS" /usr/local/bin
}

install_from_github "sharkdp" "bat" "-x86_64-unknown-linux-gnu.tar.gz" "bat"
install_from_github "github" "hub" "hub-linux-amd64" "bin/hub"
install_from_github "so-fancy" "diff-so-fancy" "__TARBALL__" "diff-so-fancy"

# Force ZSH as default shell
echo "exec zsh" > ~/.bashrc
