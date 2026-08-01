#!/usr/bin/env bash
# Run a command (default: an interactive shell) in a dingzhi test container
# with the working tree mounted at ~/dingzhi.
#
# Usage:
#   tests/docker-run.sh [--nosudo] [--with-claude-auth] [--] [command ...]
#
# Examples:
#   tests/docker-run.sh
#   tests/docker-run.sh --nosudo -- bash -c 'bats tests/unit'
#   tests/docker-run.sh -- bash tests/integration/install-twice.sh
#
# --with-claude-auth mounts your ~/.claude credentials into the container so
# `claude` is already logged in. It exposes your Claude Code login to whatever
# runs inside; leave it off unless you need it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE=dingzhi-sudo
MOUNTS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --nosudo) IMAGE=dingzhi-nosudo; shift ;;
        --with-claude-auth)
            [[ -d "$HOME/.claude" ]] && MOUNTS+=(-v "$HOME/.claude:/home/dev/.claude")
            [[ -f "$HOME/.claude.json" ]] && MOUNTS+=(-v "$HOME/.claude.json:/home/dev/.claude.json")
            shift ;;
        --) shift; break ;;
        -*) echo "unknown option: $1" >&2; exit 1 ;;
        *) break ;;
    esac
done

if [[ $# -eq 0 ]]; then
    set -- /bin/bash
fi

# Only allocate a TTY when we actually have one, so this works from a script
# or a CI job as well as from a terminal.
TTY_FLAGS=(-i)
[[ -t 0 && -t 1 ]] && TTY_FLAGS+=(-t)

exec docker run --rm "${TTY_FLAGS[@]}" \
    -v "$REPO_ROOT:/home/dev/dingzhi" \
    ${MOUNTS[@]+"${MOUNTS[@]}"} \
    "$IMAGE" \
    "$@"
