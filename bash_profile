eval "$(hub alias -s)"

eval "$(thefuck --alias)"

if brew command command-not-found-init > /dev/null; then eval "$(brew command-not-found-init)"; fi

if [ -f ~/.homebrew_github_api_token ]; then . ~/.homebrew_github_api_token; fi

if [ -f $(brew --prefix)/etc/bash_completion ]; then . $(brew --prefix)/etc/bash_completion; fi

export GPG_TTY=$(tty)

export GOPATH=$HOME/dev/golang
export PATH=$PATH:$GOPATH/bin

eval $(/usr/libexec/path_helper -s)
