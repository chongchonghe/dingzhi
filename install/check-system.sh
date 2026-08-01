#!/usr/bin/env bash
# Abort early, before anything is written, if this machine cannot be supported.
#
# Sourced by install.sh. Requires lib/detect.sh and lib/ui.sh.

if [ "$DINGZHI_OS" = "unsupported" ]; then
    die "$(uname -s) is not supported. dingzhi runs on macOS and Linux."
fi

for _required in curl git; do
    command -v "$_required" >/dev/null 2>&1 \
        || die "'$_required' is required but not installed. Install it and re-run."
done
unset _required

if [ "$DINGZHI_OS" = "linux" ] && [ "$DINGZHI_ARCH" != "x86_64" ]; then
    warn "Linux on $DINGZHI_ARCH is untested: the release binaries dingzhi"
    warn "downloads for the no-root backend are x86_64-only. Packages from apt"
    warn "will work; anything fetched from GitHub releases will not run."
fi

say "System check passed: $DINGZHI_OS/$DINGZHI_ARCH, backend=$DINGZHI_BACKEND"
