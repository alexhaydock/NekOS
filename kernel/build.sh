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
arch="$(uname -m)"
case "$arch" in
    "x86_64" | "amd64")
        if ! echo '5400170a711abb98f383e15f65a835eed104311631925b796580c25384a7b838  build/kernel' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
    "aarch64" | "arm64")
        if ! echo '0000000000000000000000000000000000000000000000000000000000000000  build/kernel' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            # TODO: ARM builds are not yet fully reproducible.
            #exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
esac
