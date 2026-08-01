#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "HOME is redirected away from the real home" {
    [ "$HOME" != "/home/dev" ]
    [ "$HOME" != "/root" ]
    [ -d "$HOME" ]
}

@test "DINGZHI_PATH points at the repository root" {
    [ -f "$DINGZHI_PATH/version" ]
}

@test "version file contains a semver string" {
    run cat "$DINGZHI_PATH/version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "the container has the Claude Code CLI" {
    run claude --version
    [ "$status" -eq 0 ]
}

@test "the container has the agentic-coding toolkit" {
    # Skipped on dingzhi-clean, which is built without it on purpose.
    command -v gh >/dev/null 2>&1 || skip "built with WITH_DEV_TOOLS=0"

    for c in ssh ssh-keygen git-lfs gh gpg rsync wget gcc g++ make pkg-config \
             python3 pip3 tree htop nano file zip; do
        command -v "$c" >/dev/null 2>&1 || { echo "missing: $c"; return 1; }
    done
}

@test "the toolkit does not preinstall dingzhi-managed apps" {
    # A preinstalled app would make its own installer's test pass vacuously.
    # gh is the one deliberate exception; see tests/Dockerfile.
    for c in bat eza fd fdfind fzf rg zoxide delta jq tldr stow \
             tmux nvim vim cmake pandoc pdftotext magick ffmpeg \
             pngquant jpegoptim cwebp yazi vifm zsh kitty lazygit; do
        if command -v "$c" >/dev/null 2>&1; then
            echo "unexpectedly preinstalled: $c"
            return 1
        fi
    done
}

@test "the governing documents travel with the repository" {
    # These must be reachable from the working tree alone. Anything that
    # depends on a second mount is lost the moment someone starts the
    # container with a plain `docker run`.
    [ -f "$DINGZHI_PATH/docs/design.md" ]
    [ -f "$DINGZHI_PATH/docs/plan.md" ]
    [ -f "$DINGZHI_PATH/start-in-docker.md" ]
}

@test "the porting source is mounted, and read-only" {
    # Needed by plan tasks 9, 11, and 13. Absent when dingzhi is checked out
    # standalone, which is fine — those tasks are already done by then.
    [ -n "${DINGZHI_SOURCE:-}" ] || skip "no porting source mounted"

    for d in dotfiles/kitty dotfiles/nvim dotfiles/tmux dotfiles/yazi \
             dotfiles/vifm dotfiles/bat dotfiles/lazygit dotfiles/cheat \
             dotfiles/git dotfiles/vim; do
        [ -e "$DINGZHI_SOURCE/$d" ] || { echo "missing source: $d"; return 1; }
    done
    for f in bin/myconvert bin/compressimage; do
        [ -f "$DINGZHI_SOURCE/$f" ] || { echo "missing source: $f"; return 1; }
    done

    run touch "$DINGZHI_SOURCE/dotfiles/kitty/should-not-be-writable"
    [ "$status" -ne 0 ]
}

@test "the porting source exposes only what the spec ships" {
    [ -n "${DINGZHI_SOURCE:-}" ] || skip "no porting source mounted"

    # Deliberately excluded by the spec. If these appear, the mount was widened
    # and someone can port content the design says stays behind.
    for d in doom raycast spacemacs vscode iTerm2 Rectangle mbsync \
             markdown-themes org-styles ghostty; do
        [ ! -e "$DINGZHI_SOURCE/dotfiles/$d" ] \
            || { echo "unexpectedly exposed: dotfiles/$d"; return 1; }
    done
    for f in arxiv ads mathpix quokka runqk qkclsh mkproj toggle-theme; do
        [ ! -e "$DINGZHI_SOURCE/bin/$f" ] \
            || { echo "unexpectedly exposed: bin/$f"; return 1; }
    done
}

@test "ssh has a usable home directory" {
    [ -d "/home/dev/.ssh" ]
    [ "$(stat -c '%a' /home/dev/.ssh)" = "700" ]
}
