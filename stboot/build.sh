#!/usr/bin/env bash
set -euo pipefail

# Copy kernel and initramfs into src/ directory
cp -fv ../kernel/build/kernel src/kernel
cp -fv ../userland/build/initramfs src/initramfs

# Copy Secure Boot keys from sbkeys build
cp -fv ../sbkeys/keys/* keys/

# Build System Transparency bootloader and image
podman build -t stboot .

# Run container to copy stboot UKI, OS image, and
# JSON manifest  into output dir
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp stboot -fv /opt/stboot.uki /opt/out/stboot.uki
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp stboot -fv /opt/nekos.json /opt/out/nekos.json
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp stboot -fv /opt/nekos.zip /opt/out/nekos.zip
