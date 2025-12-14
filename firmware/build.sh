#!/usr/bin/env bash
set -euo pipefail

# Build base container Nix
podman build -t firmwarebuilder .

# Run build inside base container
#
# We do this differently to other stages since
# the Nix sandbox requires the use of --privileged
podman run --rm -it \
    --privileged \
    -v "$(pwd)/build:/opt/out:Z" \
    firmwarebuilder

# Validate build hash based on architecture
arch="$(uname -m)"
case "$arch" in
    "x86_64" | "amd64")
        if ! echo 'be3cf92e8ae2fe8d171cef616484c5e26f023dd96c95d933373378bf762cbdee  build/firmware.fd' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
    "aarch64" | "arm64")
        if ! echo '0000000000000000000000000000000000000000000000000000000000000000  build/firmware.fd' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            # TODO: ARM builds are not yet fully reproducible.
            # Not sure why. (It's not the truncate step)
            #exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
esac
