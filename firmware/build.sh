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
        if ! echo '01b673bbb8e9bf7770b98fd2e8987c231b14a92367fe5988a975a43594ab25f2  build/firmware.fd' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
    "aarch64" | "arm64")
        if ! echo 'd36ce4fa3cf12f2e8491a101a77727bf87d705b4784c485cabfa51cf81461d7e  build/firmware.fd' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
esac
