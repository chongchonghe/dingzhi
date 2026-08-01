#!/usr/bin/env bash
# Run a command (default: an interactive shell) in a dingzhi test container
# with the working tree mounted at ~/dingzhi.
#
# Usage:
#   tests/docker-run.sh [--nosudo|--clean] [--with-claude-auth] [--ssh]
#                       [--gh-auth] [--] [command ...]
#
# Examples:
#   tests/docker-run.sh
#   tests/docker-run.sh --nosudo -- bash -c 'bats tests/unit'
#   tests/docker-run.sh -- bash tests/integration/install-twice.sh
#   tests/docker-run.sh --with-claude-auth --ssh --gh-auth
#
# Image variants:
#   (default)  dingzhi-sudo    apt backend
#   --nosudo   dingzhi-nosudo  eget+pixi, user cannot escalate
#   --clean    dingzhi-clean   apt backend without the agentic toolkit; use it
#                              to test installers the toolkit would preinstall
#
# Credential forwarding — each of these hands something private to whatever
# runs in the container. Leave them off unless you need them.
#   --with-claude-auth  mounts ~/.claude and ~/.claude.json (Claude Code login)
#   --ssh               forwards your ssh-agent socket (your ssh keys)
#   --gh-auth           passes a GitHub token through as GH_TOKEN
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE=dingzhi-sudo
MOUNTS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --nosudo) IMAGE=dingzhi-nosudo; shift ;;
        --clean)  IMAGE=dingzhi-clean; shift ;;
        --ssh)
            # Forward the host ssh-agent so git over ssh works in the container.
            if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
                MOUNTS+=(-v "$SSH_AUTH_SOCK:/ssh-agent" -e "SSH_AUTH_SOCK=/ssh-agent")
            else
                echo "warning: SSH_AUTH_SOCK is unset; nothing to forward" >&2
            fi
            shift ;;
        --gh-auth)
            # Forward a GitHub token so `gh` is authenticated in the container.
            if [[ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]]; then
                MOUNTS+=(-e "GH_TOKEN=${GH_TOKEN:-$GITHUB_TOKEN}")
            elif command -v gh >/dev/null 2>&1 && gh auth token >/dev/null 2>&1; then
                MOUNTS+=(-e "GH_TOKEN=$(gh auth token)")
            else
                echo "warning: no GitHub token found; run 'gh auth login' first" >&2
            fi
            shift ;;
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

# While dingzhi still lives inside the tools repo, mount the spec and plan
# read-only at ~/plan so an agent working in the container can read them.
# Harmless once dingzhi is published standalone: the directory just won't exist.
PARENT_DOCS="$(cd "$REPO_ROOT/../.." 2>/dev/null && pwd)/docs/superpowers"
if [[ -d "$PARENT_DOCS" ]]; then
    MOUNTS+=(-v "$PARENT_DOCS:/home/dev/plan:ro")
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
