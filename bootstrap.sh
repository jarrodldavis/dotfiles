#!/bin/sh
set -eu

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
REPOSITORY="https://github.com/jarrodldavis/dotfiles.git"
NIX_PROFILE="/nix/var/nix/profiles/default"
NIX_INSTALLER="https://artifacts.nixos.org/nix-installer"

  bold="$(tput bold)"
 reset="$(tput sgr0)"
 white="$(tput setaf 7)"
  blue="$(tput setaf 4)"
 green="$(tput setaf 2)"
_log    (){ local color="$1"; shift; printf '%s%s==> %s%s%s\n' "$bold" "$color" "$white" "$*" "$reset"; }
info    (){ _log "$blue"   "$@"; }
success (){ _log "$green"  "$@"; }

if ! command -v nix; then
    export PATH="$NIX_PROFILE/bin:$PATH"
fi

if ! command -v nix; then
    info 'Installing Nix...'
    curl --proto '=https' --tlsv1.2 -sSfL "$NIX_INSTALLER" |
        sh -s -- install --enable-flakes --no-confirm
else
    success 'Nix is already installed:'
    nix --version
fi

if [ ! -d "$DOTFILES/.git" ]; then
    if [ -e "$DOTFILES" ]; then
        info "$DOTFILES exists but is not a Git repository." >&2
        exit 1
    fi

    info 'Cloning dotfiles repository...'
    nix shell nixpkgs#git --command git clone "$REPOSITORY" "$DOTFILES"
else
    success 'Dotfiles have already been cloned:'
    git -C "$DOTFILES" status
fi

info "Applying configuration from $DOTFILES..."
cd "$DOTFILES"
nix run "path:$DOTFILES#apply"

success 'Dotfiles installed successfully!'
