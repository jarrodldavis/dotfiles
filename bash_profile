if [ -f $(brew --prefix)/etc/bash_completion ]; then . $(brew --prefix)/etc/bash_completion; fi

export GPG_TTY=$(tty)

eval "$(hub alias -s)"

export PATH=$HOME/.dotfiles/scripts:$PATH
