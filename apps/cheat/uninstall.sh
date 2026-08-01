#!/usr/bin/env bash
pkg_remove cheat
unlink_managed "$HOME/.config/cheat/conf.yml" "cheat config"
# The community cheatsheets clone is left in place: it is a few megabytes the
# user may have edited, and removing it is not what "uninstall cheat" implies.
