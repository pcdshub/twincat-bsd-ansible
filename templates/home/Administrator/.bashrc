#!/usr/bin/env bash
# shellcheck disable=SC2139

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Include Beckhoff defaults from sh:
alias h='fc -l'
alias j=jobs
alias m="$PAGER"
alias ll='ls -laFo'
alias l='ls -l'
alias g='egrep -i'
alias sudo=doas

# Include bash tab completion:
[ -f " /usr/local/share/bash-completion/bash_completion.sh" ] && \
  source /usr/local/share/bash-completion/bash_completion.sh

# A basic prompt change to remind us where we are:
_get_twincat_mode() {
  TcSysExe.exe --mode | sed -Ee 's/TwinCAT mode:[[:space:]]*//' 2>/dev/null
}

export PS1='[TCBSD: $(_get_twincat_mode)] \[\e[0;31m\][\u@\h  \W]\$\[\e[m\] '

# Additional settings:
export EDITOR=vi

# Additional aliases and tweaks of existing ones:
alias ls='ls --color'
alias lh='ls -lh'
