#!/usr/bin/env bash
set -euo pipefail

# Copy kernel and initramfs into src/ directory
cp -fv ../kernel/build/kernel src/kernel
cp -fv ../userland/build/initramfs src/initramfs

# Copy Secure Boot keys from keygen build
cp -fv ../keygen/keys/* keys/

# Build UKI
podman build --target final -t uki .

# Run container (debug version)
#podman run --rm -it uki

# Run container to copy UKI into output dir
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp uki -fv /opt/uki.unsigned.efi /opt/out/uki.unsigned.efi
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp uki -fv /opt/uki.efi /opt/out/uki.efi

# Hash output
sha256sum \
  build/uki.unsigned.efi \
  build/uki.efi

# Validate build hash based on architecture
# (we do this for the unsigned UKI only since the signed one
# depends on cryptographic private keys which independent
# verifiers aren't going to be in possession of)
arch="$(uname -m)"
case "$arch" in
    "x86_64" | "amd64")
        if ! echo '3c1dd15443a55e5440f3fa17076ffb28fd55bdfebcc034123372fe4e7ae17b15  build/uki.unsigned.efi' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
    "aarch64" | "arm64")
        if ! echo '0000000000000000000000000000000000000000000000000000000000000000  build/uki.unsigned.efi' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
esac
