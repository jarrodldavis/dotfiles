eval "$(hub alias -s)"
eval "$(thefuck --alias)"

eval "$(nodenv init -)"

if [ -f ~/.homebrew_github_api_token ]; then . ~/.homebrew_github_api_token; fi

if [ -f $(brew --prefix)/etc/bash_completion ]; then . $(brew --prefix)/etc/bash_completion; fi

export GPG_TTY=$(tty)

export GOPATH=$HOME/dev/golang
export PATH=$GOPATH/bin:$PATH

export PATH=$HOME/dev/flutter/bin:$PATH
