#!/usr/bin/env bash
pkg_remove bat
unlink_managed "$HOME/.config/bat" "bat config"
rm -f "$HOME/.local/bin/bat"
