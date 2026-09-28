#!/usr/bin/env bash

set -e

# librime binaries and headers are vendored in librime/dist.
# Set update_librime=1 to refresh them from the upstream release below.
rime_version=1.16.0
rime_git_hash="a251145"

if [ -n "${update_librime}" ]; then
    rime_archive="rime-${rime_git_hash}-macOS-universal.tar.bz2"
    rime_download_url="https://github.com/rime/librime/releases/download/${rime_version}/${rime_archive}"

    rime_deps_archive="rime-deps-${rime_git_hash}-macOS-universal.tar.bz2"
    rime_deps_download_url="https://github.com/rime/librime/releases/download/${rime_version}/${rime_deps_archive}"

    mkdir -p download && (
        cd download
        [ -z "${no_download}" ] && curl -LO "${rime_download_url}"
        tar --bzip2 -xf "${rime_archive}"
        [ -z "${no_download}" ] && curl -LO "${rime_deps_download_url}"
        tar --bzip2 -xf "${rime_deps_archive}"
    )

    # merges into librime/dist, keeping vendored extra headers (rime/key_table.h, X11/)
    cp -R download/dist librime/
fi

make copy-rime-binaries

# install Rime recipes
rime_dir=plum/output bash plum/rime-install
make copy-plum-data
