#!/usr/bin/env bash
# group: editors
pkg_install vim
manage_symlink "$DINGZHI_PATH/configs/vim/vimrc" "$HOME/.vimrc" "vim config"
