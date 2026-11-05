#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

sudo dnf install -y libdnf5-plugin-actions createrepo_c curl util-linux

install_executable discord/refresh-repo.bash /usr/local/libexec/refresh-discord-rpm-repo
install_config discord/discord-local.repo /etc/yum.repos.d/discord-local.repo
install_config discord/discord.actions /etc/dnf/libdnf5-plugins/actions.d/discord.actions

sudo dnf makecache --refresh
dnf repoquery --repo discord-local discord
