# Test container for dingzhi.
#
#   docker build -t dingzhi-sudo   --build-arg WITH_SUDO=1 -f tests/Dockerfile .
#   docker build -t dingzhi-nosudo --build-arg WITH_SUDO=0 -f tests/Dockerfile .
#   docker build -t dingzhi-clean  --build-arg WITH_DEV_TOOLS=0 -f tests/Dockerfile .
#
# WITH_SUDO=1 exercises the apt backend; WITH_SUDO=0 exercises eget+pixi.
# WITH_DEV_TOOLS=1 adds an agentic-coding toolkit (ssh, gh, git-lfs, compilers).
#
# The dingzhi working tree is mounted at run time (see tests/docker-run.sh),
# not copied in, so editing a script never requires a rebuild.
FROM ubuntu:24.04

ARG WITH_SUDO=1
ARG WITH_DEV_TOOLS=1
ARG USERNAME=dev
ARG NODE_MAJOR=22

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# The minimum a bare machine has, plus bats and shellcheck for the test suite.
# Deliberately NOT installing anything dingzhi installs — a preinstalled app
# would make its installer's test pass vacuously.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git sudo locales xz-utils unzip \
        bats shellcheck procps less \
    && rm -rf /var/lib/apt/lists/*

# Node.js — required by the Claude Code CLI.
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Agentic-coding toolkit.
#
# Every package here is one dingzhi does NOT manage, so adding it cannot mask
# a broken dingzhi installer. The single exception is `gh`, installed below —
# see the note there.
#
# git-lfs matters specifically: the gitconfig dingzhi ships declares
# [filter "lfs"], so cloning an LFS repository fails without it.
# ---------------------------------------------------------------------------
RUN if [ "$WITH_DEV_TOOLS" = "1" ]; then \
        apt-get update && apt-get install -y --no-install-recommends \
            openssh-client \
            git-lfs \
            gnupg \
            rsync \
            wget \
            build-essential \
            pkg-config \
            python3-pip \
            python3-venv \
            man-db \
            tree \
            htop \
            nano \
            file \
            iputils-ping \
            dnsutils \
            zip \
        && rm -rf /var/lib/apt/lists/* ; \
    fi

# GitHub CLI from the official repository.
#
# NOTE: `gh` is also a dingzhi app (github-cli, git group). With it preinstalled,
# `pkg_installed github-cli` is true and dingzhi's own gh installer is never
# exercised. Build dingzhi-clean (WITH_DEV_TOOLS=0) to test that installer.
RUN if [ "$WITH_DEV_TOOLS" = "1" ]; then \
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
        && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            > /etc/apt/sources.list.d/github-cli.list \
        && apt-get update && apt-get install -y --no-install-recommends gh \
        && rm -rf /var/lib/apt/lists/* ; \
    fi

# Ubuntu 24.04 ships a uid-1000 'ubuntu' user; remove it so ours can take 1000.
RUN userdel -r ubuntu 2>/dev/null || true
RUN useradd -m -s /bin/bash -u 1000 "$USERNAME"

# The whole point of the nosudo image is that this user cannot escalate.
RUN if [ "$WITH_SUDO" = "1" ]; then \
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$USERNAME" && \
        chmod 0440 /etc/sudoers.d/"$USERNAME" ; \
    else \
        rm -f /etc/sudoers.d/"$USERNAME" ; \
    fi

USER $USERNAME
WORKDIR /home/$USERNAME

ENV PATH="/home/${USERNAME}/.local/bin:/home/${USERNAME}/local/bin:/home/${USERNAME}/.pixi/bin:${PATH}"

# ssh needs a ~/.ssh with correct permissions before it will use a mounted key.
RUN mkdir -p "/home/${USERNAME}/.ssh" && chmod 700 "/home/${USERNAME}/.ssh"

# Claude Code CLI, installed as the unprivileged user into ~/.local/bin.
RUN npm config set prefix "/home/${USERNAME}/.local" \
    && npm install -g @anthropic-ai/claude-code \
    && claude --version

WORKDIR /home/$USERNAME/dingzhi

CMD ["/bin/bash", "-l"]
