#!/usr/bin/env bash

# https://github.com/microsoft/vscode-dev-containers/blob/v0.122.1/containers/debian-10-git/.devcontainer/Dockerfile

USERNAME=vscode
USER_UID=1000
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

# Install hub
apt-get -y install hub

# Install starship prompt
curl -fsSL https://starship.rs/install.sh | bash -s -- --yes

# Install diff-so-fancy
mkdir -p /opt/diff-so-fancy/
curl -fsSL https://github.com/so-fancy/diff-so-fancy/archive/v1.3.0.tar.gz | tar -xz -C /opt/diff-so-fancy --strip-components=1
ln -sf /opt/diff-so-fancy/diff-so-fancy /usr/local/bin

# Copy configs
cp ~/.dotfiles/zshrc ~/.zshrc
cp ~/.dotfiles/zprofile ~/.zprofile
cp ~/.dotfiles/starship.toml ~/.starship.toml
sed -i "s/export EDITOR='vim'/export EDITOR='code --wait'/" ~/.zshrc

# Set EDITOR to Visual Studio Code

# Clean up
apt-get autoremove -y
apt-get clean -y
rm -rf /var/lib/apt/lists/*
