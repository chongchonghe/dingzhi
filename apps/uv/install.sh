#!/usr/bin/env bash
# group: dev
# uv is installed during bootstrap, because the package table routes
# trash-cli and thefuck through it. This confirms and reports.
if command -v uv >/dev/null 2>&1; then
    skip "uv already installed ($(uv --version))"
else
    step "installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
    export PATH="$HOME/.local/bin:$PATH"
fi
