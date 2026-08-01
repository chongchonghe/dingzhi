#!/usr/bin/env bash
# group: core
pkg_install git-delta

# The shipped gitconfig includes this path. Linking the vendored theme there
# keeps the include out of the checkout, so git works wherever dingzhi lives.
manage_symlink "$DINGZHI_PATH/themes/catppuccin/delta.gitconfig" \
    "$HOME/.config/dingzhi-delta-theme.gitconfig" \
    "delta catppuccin theme"
