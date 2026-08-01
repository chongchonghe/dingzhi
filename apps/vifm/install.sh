#!/usr/bin/env bash
# group: filemanagers
pkg_install vifm
manage_symlink "$DINGZHI_PATH/configs/vifm" "$HOME/.config/vifm" "vifm config"
