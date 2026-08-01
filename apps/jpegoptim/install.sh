#!/usr/bin/env bash
# group: media
# jpegoptim is not packaged on conda-forge, so the no-root backend cannot
# install it. compressimage already falls back to cjpeg/djpeg for JPEG when
# jpegoptim is missing, so this costs some compression quality, not the feature.
if [ -z "$(pkg_resolve jpegoptim "$DINGZHI_BACKEND")" ]; then
    warn "jpegoptim is unavailable on the $DINGZHI_BACKEND backend"
    warn "compressimage will fall back to cjpeg/djpeg for JPEG files"
else
    pkg_install jpegoptim
fi
