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

@test "ssh has a usable home directory" {
    [ -d "/home/dev/.ssh" ]
    [ "$(stat -c '%a' /home/dev/.ssh)" = "700" ]
}
