#!/usr/bin/env bash
# group: core
pkg_install fd

# Debian ships the binary as fdfind.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    step "linked fdfind -> ~/.local/bin/fd"
fi
