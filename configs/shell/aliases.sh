# shellcheck shell=bash
# Shared aliases. Sourced by init.sh.

# Listing. eza when present, otherwise plain ls with the right colour flag for
# the platform: GNU uses --color=auto, BSD/macOS uses -G.
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -l --group-directories-first --git'
    alias la='eza -la --group-directories-first --git'
    alias lt='eza --tree --level=2'
elif [ "$(uname -s)" = "Darwin" ]; then
    alias ls='ls -GFh'
    alias ll='ls -GFhl'
    alias la='ls -GFhla'
    alias lt='ls -GFhltr'
else
    alias ls='ls -Fh --color=auto'
    alias ll='ls -Fhl --color=auto'
    alias la='ls -Fhla --color=auto'
    alias lt='ls -Fhltr --color=auto'
fi

# Debian names these binaries differently; the app installers add shims, but
# alias them too so a shell works even if the shim is missing.
command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1 && alias bat='batcat'
command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1 && alias fd='fdfind'

command -v nvim >/dev/null 2>&1 && alias vi='nvim'
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'
command -v cheat >/dev/null 2>&1 && alias ch='cheat'

# Safety. These are deliberate: an interactive prompt has saved more data than
# it has ever cost in keystrokes.
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

alias le='less -R'
alias ..='cd ..'
alias ...='cd ../..'
alias m='make'
alias sizesort='du -s -- * | sort -n'
alias myrsync='rsync -avh'
alias myrsyncbar='rsync -ah --info=progress2'

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gw='git worktree'
