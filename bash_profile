if [ -f $(brew --prefix)/etc/bash_completion ]; then . $(brew --prefix)/etc/bash_completion; fi

export GPG_TTY=$(tty)

eval "$(hub alias -s)"

export PATH=$HOME/.dotfiles/scripts:$PATH

export EDITOR=vim

if [ $TERM_PROGRAM == 'Apple_Terminal' ]
then
    # Git Prompt
    source /usr/local/etc/bash_completion.d/git-prompt.sh
    PS1_COLOR_START='\e[0;37m\e[2m'; # dim text + light gray
    PS1_COLOR_STOP='\e[m'
    PS1_USER_INFO='\u@\h:\w' # user@host:path
    PS1_DATE='[\d \@]' # [date 12-hour-time]

    function __prompt_command_git {
        __git_ps1 "${PS1_COLOR_START}${PS1_DATE} ${PS1_USER_INFO}" "\n${PS1_COLOR_STOP}\$ "
    }

    PROMPT_COMMAND='__prompt_command_git && update_terminal_cwd'
    GIT_PS1_SHOWDIRTYSTATE=true
    GIT_PS1_SHOWSTASHSTATE=true
    GIT_PS1_SHOWUNTRACKEDFILES=true
    GIT_PS1_SHOWUPSTREAM='auto verbose name'
    GIT_PS1_DESCRIBE_STYLE='branch'
fi
