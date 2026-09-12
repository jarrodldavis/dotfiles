#!/usr/bin/env bash
set -euo pipefail
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring shells...'

ensure_source_block() {
  local file="$1"
  local name="$2"
  local target="$3"

  local begin="# >>> dotfiles:${name} >>>"
  local end="# <<< dotfiles:${name} <<<"

  local block="${begin}
export DOTFILES=\"\${DOTFILES:-\$HOME/.dotfiles}\"
[[ -r \"\$DOTFILES/${target}\" ]] && source \"\$DOTFILES/${target}\"
${end}"

  mkdir -p "$(dirname -- "$file")"
  touch "$file"

  local tmp="${file}.tmp.$$"
  local in_block=0
  local found=0
  local line

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$begin" ]]; then
      found=1
      in_block=1
      printf '%s\n' "$block" >> "$tmp"
      continue
    fi

    if (( in_block )); then
      if [[ "$line" == "$end" ]]; then
        in_block=0
      fi
      continue
    fi

    printf '%s\n' "$line" >> "$tmp"
  done < "$file"

  if (( ! found )); then
    {
      printf '\n'
      printf '%s\n' "$block"
    } >> "$tmp"
  fi

  mv "$tmp" "$file"
}

ensure_source_block "$HOME/.zshenv"   env     "configs/zsh/env.zsh"
ensure_source_block "$HOME/.zprofile" profile "configs/zsh/profile.zsh"
ensure_source_block "$HOME/.zshrc"    rc      "configs/zsh/rc.zsh"

ensure_source_block "$HOME/.bash_profile"   profile "configs/bash/profile.bash"
ensure_source_block "$HOME/.bashrc"         rc      "configs/bash/rc.bash"
