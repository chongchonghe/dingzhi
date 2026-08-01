# Test container for dingzhi.
#
#   docker build -t dingzhi-sudo   --build-arg WITH_SUDO=1 -f tests/Dockerfile .
#   docker build -t dingzhi-nosudo --build-arg WITH_SUDO=0 -f tests/Dockerfile .
#
# WITH_SUDO=1 exercises the apt backend; WITH_SUDO=0 exercises eget+pixi.
#
# The dingzhi working tree is mounted at run time (see tests/docker-run.sh),
# not copied in, so editing a script never requires a rebuild.
FROM ubuntu:24.04

ARG WITH_SUDO=1
ARG USERNAME=dev
ARG NODE_MAJOR=22

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# The minimum a bare machine has, plus bats and shellcheck for the test suite.
# Deliberately NOT installing anything dingzhi itself installs — that is what
# these containers exist to test.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git sudo locales xz-utils unzip \
        bats shellcheck procps less \
    && rm -rf /var/lib/apt/lists/*

# Node.js — required by the Claude Code CLI.
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

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

# Claude Code CLI, installed as the unprivileged user into ~/.local/bin.
RUN npm config set prefix "/home/${USERNAME}/.local" \
    && npm install -g @anthropic-ai/claude-code \
    && claude --version

WORKDIR /home/$USERNAME/dingzhi

CMD ["/bin/bash", "-l"]
