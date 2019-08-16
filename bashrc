#! /usr/bin/env bash

# Environment variables
export EDITOR=vim
export PATH=$HOME/.dotfiles-scripts:$HOME/.dotfiles-scripts/bash:$PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Bash options
# shellcheck disable=SC2143
if [ "$(shopt -p | grep -q globstar)" ]; then shopt -s globstar; fi

# Check for updated bash
echo "Welcome to bash v$BASH_VERSION"

function __color_log() {
  local message=$2
  if [[ -t 1 ]] && tput colors &> /dev/null; then
    local message="\033[${1}m${2}\033[0m"
  fi
  echo -e "$message"
}

# A `$0` value of `-bash` (with a leading hyphen) indicates the current shell process is a top-level login shell
# Otherwise the current shell process is (most likely) a sub-shell
# `$SHELL` always refers to the top-level login shell, even in sub-shells
if [ "$SHELL" != "$(command -v bash)" ] && [ "$0" != "-bash" ]; then
  __color_log 31 "The top-level login shell this sub-shell was spawned from is using the system-provided installation of bash, but a new version has been installed via Homebrew. If this is unexpected, be sure to update your default shell using 'chsh -s', then exit this and all other shell processes to use the new bash installation."
fi

# Check to see if the current process' bash version matches the (likely Homebrew-installed) default bash version
# If the two versions don't match, most likely the current process is the system-provided bash
if [ "$BASH_VERSION" != "$(bash -c 'echo $BASH_VERSION')" ]; then
  __color_log 31 "This shell process is using the system-provided installation of bash, but a new version has been installed via Homebrew. If this is unexpected, be sure to update your default shell using 'chsh -s', then exit this (and any other) shell process to use the new bash installation."
fi

# Prompt customization
function __prompt_command_start() {
  local PS1_COLOR_START='\e[0;37m\e[2m' # dim text + light gray
  local PS1_USER_INFO='\u@\h:\w'        # user@host:path
  local PS1_DATE='[\d \@]'              # [date 12-hour-time]

  # shell version info
  local PS1_SHELL
  local PS1_SHELL_COLOR_START
  if [ "$0" != "-bash" ]; then
    PS1_SHELL_COLOR_START='\e[0;33m' # yellow
    PS1_SHELL="${SHELL} > ${0} v\V"  # indicate that this is a sub-shell
  elif [ "$BASH_VERSION" != "$(bash -c 'echo $BASH_VERSION')" ]; then
    PS1_SHELL_COLOR_START='\e[0;31m' # red
    PS1_SHELL="$0 v\V (out-of-date)" # indicate this process is out-of-date
  else
    PS1_SHELL="$0 v\V"
  fi
  local PS1_SHELL="${PS1_SHELL_COLOR_START}${PS1_SHELL}${PS1_COLOR_START}"

  echo "${PS1_COLOR_START}${PS1_DATE} ${PS1_SHELL} ${PS1_USER_INFO}"
}

function __prompt_command_end() {
  printf "\e[m\n$ "
}

function __prompt_command_base() {
  PS1="$(__prompt_command_start) $(__prompt_command_end)"
}

if [ "$TERM_PROGRAM" == 'Apple_Terminal' ]; then
  PROMPT_COMMAND='__prompt_command_base'
fi
