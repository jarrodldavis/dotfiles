if [ $PROFILE_LOADED ]
then
    export PATH=$LOADED_PATH
    echo "Profile has already been loaded."
    return 0
fi

echo "Loading profile..."

eval "$(hub alias -s)"

eval "$(thefuck --alias)"

eval "$(nodenv init -)"

if brew command command-not-found-init > /dev/null; then eval "$(brew command-not-found-init)"; fi

if [ -f ~/.homebrew_github_api_token ]; then . ~/.homebrew_github_api_token; fi

if [ -f $(brew --prefix)/etc/bash_completion ]; then . $(brew --prefix)/etc/bash_completion; fi

export GPG_TTY=$(tty)

export GOPATH=$HOME/dev/golang
export PATH=$GOPATH/bin:$PATH

export PATH=$HOME/dev/flutter/bin:$PATH

export PROFILE_LOADED=true
export LOADED_PATH=$PATH
