set -euo pipefail

export DOTFILES_HELPERS_ONLY=1
# shellcheck source=install.bash
source ~/.dotfiles/install.bash

export BAT_STYLE="-grid"
export BAT_PAGING="never"
export GIT_CONFIG_PARAMETERS="'delta.paging'='never' 'delta.width'='variable' 'delta.side-by-side'='false'"

resolve_install_targets() {
    local func="$1"
    local -a targets=(common)

    if [[ "$(uname)" == "Darwin" ]]; then
        targets+=(macos)
    else
        if [[ -f /etc/os-release ]]; then
            # shellcheck source=/dev/null
            . /etc/os-release
        fi

        targets+=(linux)

        if [[ "${ID:-}" == "fedora" && "${VARIANT_ID:-}" == "coreos" ]]; then
            targets+=(coreos)
        fi

        if [[ "${ID:-}" == "bazzite" ]]; then
            targets+=(bazzite)
        fi

        if [[ "${REMOTE_CONTAINERS:-}" == "true" ]]; then
            targets+=(devcontainer)
        fi

        if [[ "${CODESPACES:-}" == "true" ]]; then
            targets+=(codespaces)
        fi
    fi

    "$func" "${targets[@]}"
}

ensure_dir() {
    local dir="$1"
    mkdir -vp "$dir"
}

get_link_paths() {
    case $# in
        1)
            from="$HOME/.dotfiles/configs/$1"
            to="$HOME/.$1"
            ;;
        2)
            case $1 in
                /*|./*|../*) from=$1 ;;
                *)           from="$HOME/.dotfiles/configs/$1" ;;
            esac
            to=$2
            ;;
        *)
            # shellcheck disable=SC2016
            printf 'error: invalid %s usage: expected `%s NAME [DESTINATION]`\n' "$helper" "$helper" >&2
            return 2
            ;;
    esac

    case "$from" in
        /*) from_check="$from" ;;
        *)  from_check="$(dirname "$to")/$from" ;;
    esac

    if [[ ! -e "$from_check" ]]; then
        printf 'error: source file does not exist: %s\n' "$from_check" >&2
        return 1
    fi
}

symlink() {
    local helper="symlink" from to
    get_link_paths "$@"
    ensure_dir "$(dirname "$to")"
    ln -vnfs "$from" "$to"
}

hardlink() {
    local helper="hardlink" from to
    get_link_paths "$@"
    ensure_dir "$(dirname "$to")"
    ln -vnf "$from" "$to"
}

copy() {
    local helper="copy" from to
    get_link_paths "$@"
    ensure_dir "$(dirname "$to")"
    cp -vf "$from" "$to"
}

install_with_mode() {
    local mode from to

    mode="$1"
    case "$mode" in
        ''|*[!0-7]*)
            printf 'error: invalid mode: %s\n' "$mode" >&2
            return 1
            ;;
    esac

    shift
    get_link_paths "$@"

    sudo install --debug -D -o root -g root -m "$mode" "$from" "$to"
}

install_config() {
    local helper="install_config"
    install_with_mode 0644 "$@"
}

install_executable() {
    local helper="install_executable"
    install_with_mode 0755 "$@"
}

install_secret() {
    local helper="install_secret"
    install_with_mode 0600 "$@"
}

install_readonly_secret() {
    local helper="install_readonly_secret"
    install_with_mode 0440 "$@"
}

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
