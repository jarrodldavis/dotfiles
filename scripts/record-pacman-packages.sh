#!/usr/bin/env zsh
set -euo pipefail

cd ~/.dotfiles/configs/pacman

cachyos_calamares_sha="0bf08362ce5ccafe3d8cfc929a9eed801e05e8f8"
base_packages_url="https://raw.githubusercontent.com/cachyos/cachyos-calamares/${cachyos_calamares_sha}/src/modules/pacstrap/pacstrap.conf"
bootloader_packages_url="https://raw.githubusercontent.com/cachyos/cachyos-calamares/${cachyos_calamares_sha}/src/modules/pacstrap/main.py"
default_packages_url="https://raw.githubusercontent.com/cachyos/cachyos-calamares/${cachyos_calamares_sha}/src/modules/netinstall/netinstall.yaml"
post_bootloader_packages_url="https://raw.githubusercontent.com/cachyos/cachyos-calamares/${cachyos_calamares_sha}/src/scripts/bootloader-post-setup"

base_packages="$(curl -fsSL "$base_packages_url" | yq -r '.basePackages[]')"
bootloader_packages="$(curl -fsSL "$bootloader_packages_url" | grep -E '^\s+base_packages \+=' | grep -oE '"[^"]+"' | tr -d '"')"
default_packages="$(curl -fsSL "$default_packages_url" | yq -r '.. | objects | select(.selected == true) | .packages[]?')"
kde_packages="$(curl -fsSL "$default_packages_url" | yq -r '.. | objects | select(.name == "KDE-Desktop") | .packages[]?')"
chwd_packages="$(cat /var/lib/chwd/local/**/profiles.toml | grep '^packages =' | cut -d'"' -f2 | xargs | tr ' ' '\n')"
post_bootloader_packages="$(curl -fsSL "$post_bootloader_packages_url" | grep -E '^\s+pacman' | grep -oE '[^[:space:]]+' | grep -vE '^pacman$|^-')"

echo "$base_packages" > defaults-base.txt
echo "$bootloader_packages" > defaults-bootloader.txt
echo "$default_packages" > defaults-netinstall.txt
echo "$kde_packages" > defaults-kde.txt
echo "$chwd_packages" > defaults-chwd.txt
echo "$post_bootloader_packages" > defaults-post-bootloader.txt

cat defaults-{base,bootloader,netinstall,kde,chwd,post-bootloader}.txt | sort | uniq > defaults-all.txt

pacman -Qeq | sort > installed-all.txt

comm -23 installed-all.txt defaults-all.txt > installed.txt

LOG_TEMPLATE='\033[1;%sm%b\033[0m\033[1;%sm%s\033[0m\n'
printf "$LOG_TEMPLATE" 32 '==> ' 39 'Recorded installed packages to ~/.dotfiles/configs/pacman/installed.txt'
