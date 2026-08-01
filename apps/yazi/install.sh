#!/usr/bin/env bash
# group: filemanagers
if pkg_installed yazi; then
    skip "yazi already installed"
elif [ "$DINGZHI_BACKEND" = "apt" ]; then
    pkg_install_release yazi
else
    pkg_install yazi
fi

manage_symlink "$DINGZHI_PATH/configs/yazi" "$HOME/.config/yazi" "yazi config"
