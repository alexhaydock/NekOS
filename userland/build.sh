#!/usr/bin/env bash
set -euo pipefail

# Build Toybox userland
podman build --target final -t ul .

# Run container (debug version)
#podman run --rm -it ul

# Run container
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ul -fv /opt/initramfs /opt/out/initramfs
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ul -fv /opt/initramfs.txt /opt/out/initramfs_filelist.txt

# Hash output
sha256sum build/initramfs

# Validate build hash based on architecture
arch="$(uname -m)"
case "$arch" in
    "x86_64" | "amd64")
        if ! echo '8f1e1d66e9637e46861979510e0a629827fb00ae1e1eb54ff16fdcd5e739e4fc  build/initramfs' \
            | sha256sum -c; then
            echo 'Build does not match expected checksum!'
            exit 1
        else
            echo 'Build matches expected checksum!'
        fi
    ;;
    "aarch64" | "arm64")
        if ! echo '1823835ed8c19e5536d9aaf6e87e35caf54da3ebb6ae57f24a5dbe1b1fdf8f5a  build/initramfs' \
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
