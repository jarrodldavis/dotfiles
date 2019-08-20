#! /usr/bin/env bash
# shellcheck disable=1090,1091

source ~/.bashrc

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

if [ "$(command -v rustup)" ]; then eval "$(rustup completions bash)"; fi

export TRAVIS_ENDPOINT=https://api.travis-ci.com/

# GPG
if [ "$TERM_PROGRAM" == 'Apple_Terminal' ] || [ "$TERM_PROGRAM" == 'vscode' ]; then
  GPG_TTY=$(tty)
  export GPG_TTY
  export PINENTRY_USER_DATA="USE_CURSES=1"
fi

# Git Prompt
if [ "$TERM_PROGRAM" == 'Apple_Terminal' ]; then
  function __prompt_command_git() {
    __git_ps1 "$(__prompt_command_start)" "$(__prompt_command_end)"
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
