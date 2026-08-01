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

# The design and plan live in docs/ inside this repository, so they arrive with
# the working-tree mount below. There is deliberately no second mount for them:
# an agent that starts the container any other way must still find its spec.

# Porting source. Tasks 9, 11, and 13 copy configs and two scripts out of the
# tools repo; without these the container cannot complete them.
#
# Mounted READ-ONLY, and enumerated exactly — not dotfiles/ and bin/ wholesale.
# The spec excludes doom, raycast, spacemacs, vscode, iTerm2, and every bin/
# script but two; leaving those unmounted makes the content cut physical rather
# than a rule someone has to remember. It also keeps rc/, my-computers/, and the
# rest of a personal repo out of the container entirely.
SOURCE_DOTFILES=(kitty nvim tmux yazi vifm bat lazygit cheat git vim)
SOURCE_BIN=(myconvert compressimage)

SOURCE_REPO="${DINGZHI_SOURCE_REPO:-$(cd "$REPO_ROOT/../.." 2>/dev/null && pwd)}"
if [[ -n "$SOURCE_REPO" && -d "$SOURCE_REPO/dotfiles" && -d "$SOURCE_REPO/bin" ]]; then
    for d in "${SOURCE_DOTFILES[@]}"; do
        [[ -d "$SOURCE_REPO/dotfiles/$d" ]] \
            && MOUNTS+=(-v "$SOURCE_REPO/dotfiles/$d:/home/dev/source/dotfiles/$d:ro")
    done
    for f in "${SOURCE_BIN[@]}"; do
        [[ -f "$SOURCE_REPO/bin/$f" ]] \
            && MOUNTS+=(-v "$SOURCE_REPO/bin/$f:/home/dev/source/bin/$f:ro")
    done
    MOUNTS+=(-e "DINGZHI_SOURCE=/home/dev/source")
else
    echo "warning: no porting source found (looked for dotfiles/ and bin/ under" >&2
    echo "         '${SOURCE_REPO:-<unresolved>}'). Plan tasks 9, 11, and 13 copy" >&2
    echo "         files from there and will fail. Set DINGZHI_SOURCE_REPO to the" >&2
    echo "         tools checkout, or skip those tasks." >&2
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
