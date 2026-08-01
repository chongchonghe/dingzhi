# shellcheck shell=bash
# PATH and shared environment. Sourced by init.sh.

# Remove a directory from PATH, so prepending is idempotent across re-sources.
_dingzhi_path_remove() {
    local target="$1" cleaned
    cleaned="$(printf '%s' "$PATH" | awk -v RS=':' -v ORS=':' -v t="$target" '$0 != "" && $0 != t {print}')"
    PATH="${cleaned%:}"
}

pathp() {
    if [ -d "$1" ]; then
        _dingzhi_path_remove "$1"
        export PATH="$1${PATH:+:$PATH}"
    fi
}

patha() {
    if [ -d "$1" ]; then
        _dingzhi_path_remove "$1"
        export PATH="${PATH:+$PATH:}$1"
    fi
}

pathp "$DINGZHI_PATH/bin"
pathp "$HOME/local/bin"
pathp "$HOME/.local/bin"
pathp "$HOME/.pixi/bin"

export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R}"

# Catppuccin Mocha for bat, and for anything that reads BAT_THEME.
export BAT_THEME="${BAT_THEME:-Catppuccin Mocha}"
