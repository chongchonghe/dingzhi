# shellcheck shell=bash
# macOS-specific shell configuration.

[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

alias o='open'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'

command -v kitty >/dev/null 2>&1 && alias icat='kitty +kitten icat'
