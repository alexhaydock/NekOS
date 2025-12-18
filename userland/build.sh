#!/usr/bin/env bash
set -euo pipefail

# Build Toybox userland
podman build --target final -t ul .

# Run container (debug version)
#podman run --rm -it ul

# Run container
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ul -fv /opt/initramfs /opt/out/initramfs
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ul -fv /opt/initramfs.txt /opt/out/initramfs_filelist.txt

# Validate build hash based on architecture
arch="$(uname -m)"
case "$arch" in
    "x86_64" | "amd64")
        if ! echo '0130b05adcc46b5c39f1934390704ffcf7d0829e9d962a072a5767aacfaa68ad  build/initramfs' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
    "aarch64" | "arm64")
        if ! echo '0000000000000000000000000000000000000000000000000000000000000000  build/initramfs' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
esac

# echo reminder
echo ""
echo "Userland built"
echo "Remember to rebuild the UKI if you made changes"
