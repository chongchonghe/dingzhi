#!/usr/bin/env bash
# group: git
pkg_install git

manage_symlink "$DINGZHI_PATH/configs/git/gitconfig" "$HOME/.gitconfig" "git config"
manage_symlink "$DINGZHI_PATH/configs/git/gitignore_global" \
    "$HOME/.gitignore_global" "global gitignore"
