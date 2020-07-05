#!/usr/bin/env bash

# https://github.com/microsoft/vscode-dev-containers/blob/v0.122.1/containers/debian-10-git/.devcontainer/Dockerfile

USERNAME=vscode
USER_UID=10000
USER_GID=$USER_UID

INSTALL_ZSH="true"
UPGRADE_PACKAGES="true"
COMMON_SCRIPT_SOURCE="https://raw.githubusercontent.com/microsoft/vscode-dev-containers/v0.122.1/script-library/common-debian.sh"
COMMON_SCRIPT_SHA="da956c699ebef75d3d37d50569b5fbd75d6363e90b3f5d228807cff1f7fa211c"

# Configure apt and install packages
apt-get update
export DEBIAN_FRONTEND=noninteractive

# Install man
apt-get -y install man-db

# Verify git, common tools / libs installed, add/modify non-root user, optionally install zsh
apt-get -y install --no-install-recommends curl ca-certificates 2>&1
curl -sSL  ${COMMON_SCRIPT_SOURCE} -o /tmp/common-setup.sh
([ "${COMMON_SCRIPT_SHA}" = "dev-mode" ] || (echo "${COMMON_SCRIPT_SHA} */tmp/common-setup.sh" | sha256sum -c -))
/bin/bash /tmp/common-setup.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}"
rm /tmp/common-setup.sh

## Install Live Share prerequisites
curl -fsSL https://raw.githubusercontent.com/MicrosoftDocs/live-share/master/scripts/linux-prereqs.sh | bash

# Install starship prompt
curl -fsSL https://starship.rs/install.sh | bash -s -- --yes

# Install X11 apps to test X11 forwarding
apt-get -y install x11-apps

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
    mkdir -p "$INSTALL_DIR"
    curl -fsSL $DOWNLOAD_URL | tar -xz -C "$INSTALL_DIR" --strip-components=1

    local BIN_ABS="$INSTALL_DIR/$BIN_REL"
    ln -s "$BIN_ABS" /usr/local/bin
}

install_from_github "sharkdp" "bat" "-x86_64-unknown-linux-gnu.tar.gz" "bat"
install_from_github "github" "hub" "hub-linux-amd64" "bin/hub"
install_from_github "so-fancy" "diff-so-fancy" "__TARBALL__" "diff-so-fancy"

# Force ZSH as default shell
echo "exec zsh" > ~/.bashrc

# Copy configs
cp ~/.dotfiles/zshrc ~/.zshrc
cp ~/.dotfiles/zprofile ~/.zprofile
cp ~/.dotfiles/starship.toml ~/.starship.toml

# Set EDITOR to Visual Studio Code
sed -i "s/export EDITOR='vim'/export EDITOR='code --wait'/" ~/.zshrc

# Clean up
apt-get autoremove -y
apt-get clean -y
rm -rf /var/lib/apt/lists/*
