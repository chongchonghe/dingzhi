#!/usr/bin/env bash
# Collect git identity into ~/.gitconfig.local, which the shipped gitconfig
# includes. The shipped config never contains a name or email.
#
# Requires lib/ui.sh. Honors DINGZHI_GIT_NAME / DINGZHI_GIT_EMAIL, which lets
# the installer run unattended.

if [ -f "$HOME/.gitconfig.local" ]; then
    skip "$HOME/.gitconfig.local already exists"
else
    _name="${DINGZHI_GIT_NAME:-$(prompt "Your name (for git commits)" "$(whoami)")}"
    _email="${DINGZHI_GIT_EMAIL:-$(prompt "Your email (for git commits)" "$(whoami)@localhost")}"

    cat > "$HOME/.gitconfig.local" <<EOF
# Local git identity, written by dingzhi. Not tracked by any repository.
[user]
	name = $_name
	email = $_email
EOF
    step "wrote $HOME/.gitconfig.local for $_name <$_email>"
    unset _name _email
fi
