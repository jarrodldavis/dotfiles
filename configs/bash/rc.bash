# https://docs.brew.sh/Manpage#shellenv-shell-
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
fi

if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
    case "$OSTYPE" in
        darwin*)
            if [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
                # shellcheck source=/dev/null
                source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
            fi
            ;;

        linux*)
            if [[ -n "${BASH_COMPLETION_VERSINFO+x}" && -z "${BREW_BASH_COMPLETION:-}" ]]; then
                for completion in "$HOMEBREW_PREFIX/etc/bash_completion.d/"*; do
                    # shellcheck source=/dev/null
                    [[ -f "$completion" && -r "$completion" ]] && source "$completion"
                done
                unset completion
            fi
            ;;
    esac
fi

PS0+=$'\e[1 q'
export EDITOR="vim"

if [[ "$VSCODE_INJECTION" = "1" ]]; then
    export EDITOR="code --wait"
fi

if command -v gh >/dev/null 2>&1; then
    if gh extension list | grep -q 'gh cd'; then
        eval "$(gh extension exec cd init bash)"
    fi
fi
