#!/usr/bin/env bash
# group: terminal
# tmux 3.5+ has a Landlock sandbox bug that crashes on some Linux kernels; the
# noroot spec pins 3.4 until that is fixed upstream.
pkg_install tmux

manage_symlink "$DINGZHI_PATH/configs/tmux" "$HOME/.config/tmux" "tmux config"

# The clone lands inside the checkout, because configs/tmux is symlinked to
# ~/.config/tmux. .gitignore excludes configs/tmux/plugins/ for that reason.
CATPPUCCIN_DIR="$HOME/.config/tmux/plugins/catppuccin/tmux"
if [ -d "$CATPPUCCIN_DIR" ]; then
    skip "catppuccin tmux theme already installed"
else
    step "installing catppuccin tmux theme"
    mkdir -p "$(dirname "$CATPPUCCIN_DIR")"
    git clone -q -b v2.1.3 https://github.com/catppuccin/tmux.git "$CATPPUCCIN_DIR"
fi
