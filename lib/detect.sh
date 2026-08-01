#!/usr/bin/env bash
# Platform and backend detection. Sets variables only; installs nothing.
#
# Sets: DINGZHI_PATH DINGZHI_OS DINGZHI_ARCH DINGZHI_BACKEND DINGZHI_BIN
# Defines: dingzhi_has_sudo dingzhi_is_debian_family

# Repository root, derived from this file's location. Never hardcoded.
if [ -z "${DINGZHI_PATH:-}" ]; then
    DINGZHI_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
export DINGZHI_PATH

case "$(uname -s)" in
    Darwin) DINGZHI_OS=macos ;;
    Linux)  DINGZHI_OS=linux ;;
    *)      DINGZHI_OS=unsupported ;;
esac
export DINGZHI_OS

case "$(uname -m)" in
    x86_64|amd64)  DINGZHI_ARCH=x86_64 ;;
    arm64|aarch64) DINGZHI_ARCH=arm64 ;;
    *)             DINGZHI_ARCH="$(uname -m)" ;;
esac
export DINGZHI_ARCH

# True if sudo exists and we can actually use it without an interactive
# password. -n makes this non-blocking, which matters inside containers and
# over ssh.
dingzhi_has_sudo() {
    command -v sudo >/dev/null 2>&1 || return 1
    sudo -n true >/dev/null 2>&1
}

# True on Debian, Ubuntu, and derivatives.
dingzhi_is_debian_family() {
    [ -r /etc/os-release ] || return 1
    # Read os-release in a subshell so its variables do not leak into the
    # caller's environment.
    (
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID:-}:${ID_LIKE:-}" in
            *debian*|*ubuntu*) exit 0 ;;
            *) exit 1 ;;
        esac
    )
}

# Respect a caller-supplied backend (tests, a --backend flag); otherwise detect.
if [ -z "${DINGZHI_BACKEND:-}" ]; then
    if [ "$DINGZHI_OS" = "macos" ]; then
        DINGZHI_BACKEND=brew
    elif dingzhi_is_debian_family && dingzhi_has_sudo; then
        DINGZHI_BACKEND=apt
    else
        DINGZHI_BACKEND=noroot
    fi
fi
export DINGZHI_BACKEND

case "$DINGZHI_BACKEND" in
    brew)
        if [ -x /opt/homebrew/bin/brew ]; then
            DINGZHI_BIN=/opt/homebrew/bin
        else
            DINGZHI_BIN=/usr/local/bin
        fi
        ;;
    apt)    DINGZHI_BIN=/usr/local/bin ;;
    noroot) DINGZHI_BIN="$HOME/local/bin" ;;
esac
export DINGZHI_BIN
