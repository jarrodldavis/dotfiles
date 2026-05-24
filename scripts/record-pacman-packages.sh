#!/usr/bin/env zsh
set -euo pipefail

cd ~/.dotfiles/configs/pacman

cachyos_calamares_sha="0bf08362ce5ccafe3d8cfc929a9eed801e05e8f8"
base_packages_url="https://raw.githubusercontent.com/cachyos/cachyos-calamares/${cachyos_calamares_sha}/src/modules/pacstrap/pacstrap.conf"
default_packages_url="https://raw.githubusercontent.com/cachyos/cachyos-calamares/${cachyos_calamares_sha}/src/modules/netinstall/netinstall.yaml"

base_packages="$(curl -fsSL "$base_packages_url" | yq -r '.basePackages[]')"
default_packages="$(curl -fsSL "$default_packages_url" | yq -r '.. | objects | select(.selected == true) | .packages[]?')"
kde_packages="$(curl -fsSL "$default_packages_url" | yq -r '.. | objects | select(.name == "KDE-Desktop") | .packages[]?')"
chwd_packages="$(cat /var/lib/chwd/local/**/profiles.toml | grep '^packages =' | cut -d'"' -f2 | xargs | tr ' ' '\n')"

echo "$base_packages"    > defaults-base.txt
echo "$default_packages" > defaults-netinstall.txt
echo "$kde_packages"     > defaults-kde.txt
echo "$chwd_packages"    > defaults-chwd.txt

cat defaults-{base,netinstall,kde,chwd}.txt | sort | uniq > defaults-all.txt

pacman -Qeq | sort > installed-all.txt

comm -23 installed-all.txt defaults-all.txt > installed.txt

LOG_TEMPLATE='\033[1;%sm%b\033[0m\033[1;%sm%s\033[0m\n'
printf "$LOG_TEMPLATE" 32 '==> ' 39 'Recorded installed packages to ~/.dotfiles/configs/pacman/installed.txt'
