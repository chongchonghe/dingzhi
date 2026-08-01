#!/usr/bin/env bash
# group: filemanagers
# conda-forge ships vifm for osx-64 only, so the no-root backend cannot install
# it on Linux. yazi is installed either way and covers file management there.
if [ -z "$(pkg_resolve vifm "$DINGZHI_BACKEND")" ]; then
    warn "vifm is unavailable on the $DINGZHI_BACKEND backend; yazi covers file management"
else
    pkg_install vifm
fi

# Link the config regardless: if vifm is installed by other means later, it
# should pick up dingzhi's configuration without a re-run.
manage_symlink "$DINGZHI_PATH/configs/vifm" "$HOME/.config/vifm" "vifm config"
