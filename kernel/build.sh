#!/usr/bin/env bash
set -euo pipefail

# Build base container Nix
podman build -t kernelbuilder .

# Run build inside base container
#
# We do this differently to other stages since
# the Nix sandbox requires the use of --privileged
podman run --rm -it \
    --privileged \
    -v "$(pwd)/build:/opt/out:Z" \
    kernelbuilder

# Validate build hash based on architecture
#
# I attempted to do this using fixed-output derivations inside the Nix
# build itself, but seemingly changing the outputHash inside the Nix
# file changes the derivation hash, which ends up changing the resulting
# kernel hash. I can only assume that this is down to some build paths
# leaking into the final build somehow still, but I'm not 100% sure.
arch="$(uname -m)"
case "$arch" in
    "x86_64" | "amd64")
        if ! echo 'b27672fc06e02bd49386364fae9d8d10e317103c75ba36b4808cefe46772c942  build/kernel' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
    "aarch64" | "arm64")
        if ! echo '140ca5121afae94336938fe2ac2e1e5dbeefd6181ec8572b12f82f663f7e475e  build/kernel' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
esac
