#!/usr/bin/env bash
set -euo pipefail

# Build with Nix
podman build --target final -t firmware .

# Run container (debug version)
#podman run --rm -it --entrypoint bash firmware

# Copy built firmware out of container
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp firmware -fv /opt/firmware.fd /opt/out/firmware.fd

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
        echo 'WIP'
    ;;
esac
