#! /usr/bin/env bash
# shellcheck disable=1090,1091

# Check for updated bash
echo "Welcome to bash v$BASH_VERSION"

function __color_log() {
  local message=$2
  if [[ -t 1 ]] && tput colors &> /dev/null; then
    local message="\033[${1}m${2}\033[0m"
  fi
  echo -e "$message"
}

# `-bash` (with a leading hyphen) indicates a shell is a top-level login shell
# otherwise, it's a sub-shell
if [ "$SHELL" != "$(command -v bash)" ] && [ "$0" != "-bash" ]; then
  __color_log 31 "The top-level login shell this sub-shell was spawned from is using the system-provided installation of bash, but a new version has been installed via Homebrew. If this is unexpected, be sure to update your default shell using 'chsh -s', then exit this and all other shell processes to use the new bash installation."
fi

if [ "$BASH_VERSION" != "$(bash -c 'echo $BASH_VERSION')" ]; then
  __color_log 31 "This shell process is using the system-provided installation of bash, but a new version has been installed via Homebrew. If this is unexpected, be sure to update your default shell using 'chsh -s', then exit this (and any other) shell process to use the new bash installation."
fi

if [ "$(command -v brew)" ] && [ -f "$(brew --prefix)"/etc/bash_completion ]; then
  source "$(brew --prefix)"/etc/bash_completion
fi

if [ -f ~/.github_tokens ]; then . ~/.github_tokens; fi

export GOOGLE_API_KEY=no
export GOOGLE_DEFAULT_CLIENT_ID=no
export GOOGLE_DEFAULT_CLIENT_SECRET=no
export CHROME_PATH=/Applications/Chromium.app/Contents/MacOS/Chromium
export CHROME_BIN=/Applications/Chromium.app/Contents/MacOS/Chromium

if [ "$(command -v hub)" ]; then eval "$(hub alias -s)"; fi

if [ "$(command -v rbenv)" ]; then eval "$(rbenv init -)"; fi

export PATH=$HOME/.dotfiles-scripts:$HOME/.dotfiles-scripts/bash:$PATH
export PATH="$HOME/.cargo/bin:$PATH"

export EDITOR=vim

export TRAVIS_ENDPOINT=https://api.travis-ci.com/

# GPG
if [ "$TERM_PROGRAM" == 'Apple_Terminal' ] || [ "$TERM_PROGRAM" == 'vscode' ]; then
  GPG_TTY=$(tty)
  export GPG_TTY
  export PINENTRY_USER_DATA="USE_CURSES=1"
fi

# Git Prompt
if [ "$TERM_PROGRAM" == 'Apple_Terminal' ]; then
  PS1_COLOR_START='\e[0;37m\e[2m' # dim text + light gray
  PS1_COLOR_STOP='\e[m'           # stop color from leaking to next line
  PS1_USER_INFO='\u@\h:\w'        # user@host:path
  PS1_SHELL='\s v\V'              # shell name and version
  PS1_DATE='[\d \@]'              # [date 12-hour-time]

  function __prompt_command_git() {
    __git_ps1 "${PS1_COLOR_START}${PS1_DATE} ${PS1_SHELL} ${PS1_USER_INFO}" "${PS1_COLOR_STOP}\n\$ "
  }

  export GIT_PS1_SHOWDIRTYSTATE=true
  export GIT_PS1_SHOWSTASHSTATE=true
  export GIT_PS1_SHOWUNTRACKEDFILES=true
  export GIT_PS1_SHOWUPSTREAM='auto verbose name'
  export GIT_PS1_DESCRIBE_STYLE='branch'

  if [ -f /usr/local/etc/bash_completion.d/git-prompt.sh ]; then
    source /usr/local/etc/bash_completion.d/git-prompt.sh
    PROMPT_COMMAND='__prompt_command_git && update_terminal_cwd'
  fi
fi

# shellcheck disable=SC2143
if [ "$(shopt -p | grep -q globstar)" ]; then shopt -s globstar; fi
