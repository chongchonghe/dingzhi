#!/usr/bin/env bash
# Build the dingzhi test images.
#
# Usage: tests/docker-build.sh [sudo|nosudo|both]   (default: both)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

build() {
    local variant="$1" with_sudo="$2"
    echo "==> building dingzhi-${variant} (WITH_SUDO=${with_sudo})"
    docker build \
        --build-arg "WITH_SUDO=${with_sudo}" \
        -t "dingzhi-${variant}" \
        -f tests/Dockerfile \
        .
}

case "${1:-both}" in
    sudo)   build sudo 1 ;;
    nosudo) build nosudo 0 ;;
    both)   build sudo 1; build nosudo 0 ;;
    *) echo "usage: $0 [sudo|nosudo|both]" >&2; exit 1 ;;
esac

echo "==> done"
