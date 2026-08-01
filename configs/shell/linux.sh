# shellcheck shell=bash
# Linux-specific shell configuration.

command -v xdg-open >/dev/null 2>&1 && alias o='xdg-open'
alias free='free -h'
alias df='df -h'
