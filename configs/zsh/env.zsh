# shellcheck disable=SC2206
fpath=( ~/.dotfiles/configs/zshfuncs $fpath )
autoload -Uz backblaze-upgrade
autoload -Uz codex-resets
autoload -Uz docker-reset
autoload -Uz fix-smb-permissions
