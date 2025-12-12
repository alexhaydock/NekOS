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
        if ! echo 'd30fab69a4e01c44d6a246dffdd50dffb6cf24e4e583bda654d8a56e93c445ac  build/firmware.fd' \
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
