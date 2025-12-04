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
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp uki -fv /opt/uki.efi /opt/out/uki.efi
