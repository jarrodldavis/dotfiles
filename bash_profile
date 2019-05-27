#! /usr/bin/env bash
# shellcheck disable=1090,1091

if [ -f "$(brew --prefix)"/etc/bash_completion ]; then . "$(brew --prefix)"/etc/bash_completion; fi

if [ -f ~/.github_tokens ]; then . ~/.github_tokens; fi

GPG_TTY=$(tty)
export GPG_TTY

export GOOGLE_API_KEY=no
export GOOGLE_DEFAULT_CLIENT_ID=no
export GOOGLE_DEFAULT_CLIENT_SECRET=no
export CHROME_PATH=/Applications/Chromium.app/Contents/MacOS/Chromium
export CHROME_BIN=/Applications/Chromium.app/Contents/MacOS/Chromium

eval "$(hub alias -s)"
eval "$(rbenv init -)"

export PATH=$HOME/.dotfiles-scripts:$PATH

export EDITOR=vim

export TRAVIS_ENDPOINT=https://api.travis-ci.com/

if [ "$TERM_PROGRAM" == 'Apple_Terminal' ]; then
  # Git Prompt
  source /usr/local/etc/bash_completion.d/git-prompt.sh
  PS1_COLOR_START='\e[0;37m\e[2m' # dim text + light gray
  PS1_COLOR_STOP='\e[m'
  PS1_USER_INFO='\u@\h:\w' # user@host:path
  PS1_DATE='[\d \@]'       # [date 12-hour-time]

  function __prompt_command_git() {
    __git_ps1 "${PS1_COLOR_START}${PS1_DATE} ${PS1_USER_INFO}" "${PS1_COLOR_STOP}\n\$ "
  }

  PROMPT_COMMAND='__prompt_command_git && update_terminal_cwd'
  export GIT_PS1_SHOWDIRTYSTATE=true
  export GIT_PS1_SHOWSTASHSTATE=true
  export GIT_PS1_SHOWUNTRACKEDFILES=true
  export GIT_PS1_SHOWUPSTREAM='auto verbose name'
  export GIT_PS1_DESCRIBE_STYLE='branch'
fi

shopt -s globstar
