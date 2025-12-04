#!/usr/bin/env bash
set -euo pipefail

# Copy kernel and initramfs into src/ directory
cp -fv ../kernel/build/kernel src/kernel
cp -fv ../userland/build/initramfs src/initramfs

# Copy Secure Boot keys from keygen build
cp -fv ../keygen/keys/* keys/

# TODO: Skip stboot build if we're on aarch64 since the
#       build-stboot process seems to use x86_64-specific
#       EFI code and fails on aarch64
if [ "$(uname -m)" == "x86_64" ]; then
    # Build System Transparency bootloader and image
    podman build --target final -t stboot .

    # Run container to copy stboot UKI, OS image, and
    # JSON manifest  into output dir
    podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp stboot -fv /opt/stboot.uki /opt/out/stboot.uki
    podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp stboot -fv /opt/nekos.json /opt/out/nekos.json
    podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp stboot -fv /opt/nekos.zip /opt/out/nekos.zip
fi
