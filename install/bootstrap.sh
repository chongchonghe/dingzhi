#!/usr/bin/env bash
# Install the package backend itself, then the tools every later step assumes:
# eget, uv, and gum. Everything after this point may use the TUI.
#
# Sourced by install.sh. Requires lib/detect.sh, lib/ui.sh, lib/pkg.sh.

say "Bootstrapping the $DINGZHI_BACKEND backend"

case "$DINGZHI_BACKEND" in
    brew)
        if command -v brew >/dev/null 2>&1; then
            skip "Homebrew already installed"
        else
            step "installing Homebrew"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
        ;;

    apt)
        step "refreshing apt package lists"
        sudo apt-get update -qq
        ;;

    noroot)
        mkdir -p "$DINGZHI_BIN"
        export PATH="$DINGZHI_BIN:$HOME/.pixi/bin:$PATH"

        if command -v pixi >/dev/null 2>&1; then
            skip "pixi already installed"
        else
            step "installing pixi"
            curl -fsSL https://pixi.sh/install.sh | PIXI_NO_PATH_UPDATE=1 bash
            export PATH="$HOME/.pixi/bin:$PATH"
        fi
        ;;
esac

# eget. Needed by the noroot backend, and by pkg_install_release on apt for the
# five tools Ubuntu does not package (neovim, lazygit, gh, yazi, tlrc).
if [ "$DINGZHI_OS" = "linux" ]; then
    if command -v eget >/dev/null 2>&1; then
        skip "eget already installed"
    else
        step "installing eget"
        _tmp="$(mktemp -d)"
        curl -sSL https://zyedidia.github.io/eget.sh -o "$_tmp/eget.sh"
        (
            cd "$_tmp" || exit 1
            sh eget.sh >/dev/null
            if [ "$DINGZHI_BACKEND" = "apt" ]; then
                sudo mv eget "$DINGZHI_BIN/"
            else
                mv eget "$DINGZHI_BIN/"
            fi
        )
        rm -rf "$_tmp"
        unset _tmp
    fi
fi

# uv, before gum: the package table installs trash-cli and thefuck through it.
if command -v uv >/dev/null 2>&1; then
    skip "uv already installed"
else
    step "installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# gum drives every prompt from here on.
if command -v gum >/dev/null 2>&1; then
    skip "gum already installed"
elif [ "$DINGZHI_BACKEND" = "brew" ]; then
    step "installing gum"
    brew install gum
else
    # Not in Ubuntu's repositories, so take the release binary either way.
    # Routed through _pkg_eget so it inherits the sidecar-asset exclusions.
    step "installing gum"
    if [ "$DINGZHI_BACKEND" = "apt" ]; then
        _pkg_eget charmbracelet/gum "Linux_x86_64.tar.gz" "" "$DINGZHI_BIN" 1
    else
        _pkg_eget charmbracelet/gum "Linux_x86_64.tar.gz" "" "$DINGZHI_BIN"
    fi
fi

command -v gum >/dev/null 2>&1 \
    || warn "gum unavailable; falling back to plain-text prompts"
