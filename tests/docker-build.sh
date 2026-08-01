#!/usr/bin/env bash
# Build the dingzhi test images.
#
# Usage: tests/docker-build.sh [sudo|nosudo|clean|both|all]   (default: both)
#
#   sudo    apt backend, with the agentic-coding toolkit
#   nosudo  eget+pixi no-root backend, with the agentic-coding toolkit
#   clean   apt backend, WITHOUT the toolkit — use this to honestly test the
#           installers for apps the toolkit would otherwise preinstall (gh)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

build() {
    local variant="$1" with_sudo="$2" with_dev="$3"
    echo "==> building dingzhi-${variant} (WITH_SUDO=${with_sudo} WITH_DEV_TOOLS=${with_dev})"
    docker build \
        --build-arg "WITH_SUDO=${with_sudo}" \
        --build-arg "WITH_DEV_TOOLS=${with_dev}" \
        -t "dingzhi-${variant}" \
        -f tests/Dockerfile \
        .
}

case "${1:-both}" in
    sudo)   build sudo   1 1 ;;
    nosudo) build nosudo 0 1 ;;
    clean)  build clean  1 0 ;;
    both)   build sudo   1 1; build nosudo 0 1 ;;
    all)    build sudo   1 1; build nosudo 0 1; build clean 1 0 ;;
    *) echo "usage: $0 [sudo|nosudo|clean|both|all]" >&2; exit 1 ;;
esac

echo "==> done"
