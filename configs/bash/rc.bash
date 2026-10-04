if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export EDITOR="vim"

if [ "$VSCODE_INJECTION" = "1" ]; then
    export EDITOR="code --wait"
fi

if command -v gh >/dev/null 2>&1; then
    if gh extension list | grep -q 'gh cd'; then
        eval "$(gh extension exec cd init bash)"
    fi
fi
