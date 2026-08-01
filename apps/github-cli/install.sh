#!/usr/bin/env bash
# group: git
# Needs a third-party apt repository; the release binary avoids adding one.
if pkg_installed github-cli; then
    skip "gh already installed"
elif [ "$DINGZHI_BACKEND" = "apt" ]; then
    pkg_install_release github-cli
else
    pkg_install github-cli
fi
