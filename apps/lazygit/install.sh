#!/usr/bin/env bash
# group: git
# Not in Ubuntu's repositories.
if pkg_installed lazygit; then
    skip "lazygit already installed"
elif [ "$DINGZHI_BACKEND" = "apt" ]; then
    pkg_install_release lazygit
else
    pkg_install lazygit
fi

# macOS puts lazygit's config somewhere else entirely.
if [ "$DINGZHI_OS" = "macos" ]; then
    _lg_config="$HOME/Library/Application Support/lazygit/config.yml"
else
    _lg_config="$HOME/.config/lazygit/config.yml"
fi
manage_symlink "$DINGZHI_PATH/configs/lazygit/config.yml" "$_lg_config" "lazygit config"
unset _lg_config
