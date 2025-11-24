#!/usr/bin/env bash
set -euo pipefail

# Copy kernel and initramfs into src/ directory
cp -fv ../kernel/build/bzImage src/bzImage
cp -fv ../userland/build/initramfs src/initramfs

# Copy Secure Boot keys from sbkeys build
cp -fv ../sbkeys/keys/* keys/

# Build UKI
podman build -t uki .

# Run container (debug version)
#podman run --rm -it uki

# Run container to copy UKI into output dir
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp uki -fv /opt/uki.efi /opt/out/uki.efi
