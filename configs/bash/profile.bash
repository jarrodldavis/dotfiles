if [[ "$OSTYPE" == darwin* ]]; then
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv bash)"
    fi

    if [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv bash)"
    fi

    if [[ $- == *i* && -f ~/.bashrc ]]; then
        # shellcheck source=/dev/null
        source ~/.bashrc
    fi
fi
