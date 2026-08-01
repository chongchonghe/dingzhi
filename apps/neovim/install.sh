#!/usr/bin/env bash
# group: editors
# Ubuntu 24.04 ships 0.9; the shipped config needs 0.10+, so apt falls back to
# the release binary too.
if pkg_installed neovim; then
    skip "neovim already installed"
elif [ "$DINGZHI_BACKEND" = "apt" ]; then
    pkg_install_release neovim
else
    pkg_install neovim
fi

manage_symlink "$DINGZHI_PATH/configs/nvim" "$HOME/.config/nvim" "neovim config"
