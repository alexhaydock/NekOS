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
        if ! echo '6da3fb3d8610ad8930c8069b62a15cd00f5a5827a804650f7ea6fe1eefe80728  build/firmware.fd' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
    "aarch64" | "arm64")
        if ! echo '63421b63966375af0ae5c3b6e0aade310abba34fb96f5dbb4b5f4fe2a4dccbf5  build/firmware.fd' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
esac
