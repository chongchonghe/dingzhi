#!/usr/bin/env bash
# group: core
# Not packaged for Debian, so fall back to the release binary there.
if pkg_installed tlrc; then
    skip "tlrc already installed"
elif [ "$DINGZHI_BACKEND" = "apt" ]; then
    pkg_install_release tlrc
else
    pkg_install tlrc
fi
