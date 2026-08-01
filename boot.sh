#!/usr/bin/env bash
# dingzhi bootstrap.
#
#   curl -fsSL https://raw.githubusercontent.com/chongchonghe/dingzhi/main/boot.sh | bash
#
# Environment:
#   DINGZHI_INSTALL_DIR  where to clone      (default ~/.local/share/dingzhi)
#   DINGZHI_REPO         where to clone from (default the GitHub remote)
#   DINGZHI_REF          branch or tag       (default main)
#   DINGZHI_SKIP_INSTALL clone only; used by the tests

set -e

DINGZHI_INSTALL_DIR="${DINGZHI_INSTALL_DIR:-$HOME/.local/share/dingzhi}"
DINGZHI_REPO="${DINGZHI_REPO:-https://github.com/chongchonghe/dingzhi.git}"
DINGZHI_REF="${DINGZHI_REF:-main}"

cat <<'ASCII'
   _ _              _    _
  | (_)_ _  __ _ ___| |_ (_)
  | | | ' \/ _` |_ / ' \| |
  |_|_|_||_\__, /___|_||_|_|
           |___/
ASCII

echo "=> dingzhi: a terminal environment for macOS and Linux"
echo

command -v git >/dev/null 2>&1 || {
    echo "!! git is required. Install it and re-run." >&2
    exit 1
}

if [ -d "$DINGZHI_INSTALL_DIR/.git" ]; then
    echo "=> $DINGZHI_INSTALL_DIR already exists; updating instead of cloning"
    git -C "$DINGZHI_INSTALL_DIR" fetch --quiet origin "$DINGZHI_REF"
    git -C "$DINGZHI_INSTALL_DIR" checkout --quiet "$DINGZHI_REF"
    git -C "$DINGZHI_INSTALL_DIR" pull --quiet --ff-only
elif [ -e "$DINGZHI_INSTALL_DIR" ]; then
    echo "!! $DINGZHI_INSTALL_DIR already exists and is not a dingzhi checkout." >&2
    echo "!! Move it aside, or set DINGZHI_INSTALL_DIR to somewhere else." >&2
    exit 1
else
    echo "=> cloning dingzhi into $DINGZHI_INSTALL_DIR"
    mkdir -p "$(dirname "$DINGZHI_INSTALL_DIR")"
    git clone --quiet --branch "$DINGZHI_REF" "$DINGZHI_REPO" "$DINGZHI_INSTALL_DIR"
fi

if [ "${DINGZHI_SKIP_INSTALL:-0}" = "1" ]; then
    echo "=> DINGZHI_SKIP_INSTALL set; stopping after clone"
    exit 0
fi

echo "=> starting installation"
# shellcheck source=install.sh
. "$DINGZHI_INSTALL_DIR/install.sh"
