#!/usr/bin/env bash
# group: core
pkg_install bat

# Debian ships the binary as batcat. Provide a `bat` shim so configs, aliases,
# and anything reading BAT_THEME can assume one name.
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    step "linked batcat -> ~/.local/bin/bat"
fi

manage_symlink "$DINGZHI_PATH/configs/bat" "$HOME/.config/bat" "bat config"
