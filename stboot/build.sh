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
    podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp stboot -fv /opt/stboot.efi /opt/out/stboot.efi
    podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp stboot -fv /opt/stboot.signed.efi /opt/out/stboot.signed.efi
    podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp stboot -fv /opt/nekos.json /opt/out/nekos.json
    podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp stboot -fv /opt/nekos.zip /opt/out/nekos.zip
    podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp stboot -fv /opt/nekos.signed.zip /opt/out/nekos.signed.zip
fi

# Hash output
sha256sum \
  build/stboot.efi \
  build/stboot.signed.efi \
  build/nekos.zip \
  build/nekos.signed.zip

# Validate UKI build hash based on architecture
# (we do this for the unsigned UKI only since the signed one
# depends on cryptographic private keys which independent
# verifiers aren't going to be in possession of)
arch="$(uname -m)"
case "$arch" in
    "x86_64" | "amd64")
        if ! echo '0000000000000000000000000000000000000000000000000000000000000000  build/stboot.efi' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            # TODO: Reproducibility not yet working for stboot
            #exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
    "aarch64" | "arm64")
        echo "stboot build skipped on aarch64"
    ;;
esac

# Validate NekOS ZIP based on architecture
# (we do this for the unsigned ZIP only since the signed one
# depends on cryptographic private keys which independent
# verifiers aren't going to be in possession of)
arch="$(uname -m)"
case "$arch" in
    "x86_64" | "amd64")
        if ! echo '0000000000000000000000000000000000000000000000000000000000000000  build/nekos.zip' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            # TODO: Reproducibility not yet working for stboot
            #exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
    "aarch64" | "arm64")
        echo "stboot build skipped on aarch64"
    ;;
esac
