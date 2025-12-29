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
(
    cd ..
    pytest -v tests/test_userland.py
)

# echo reminder
echo ""
echo "Userland built"
echo "Remember to rebuild the UKI if you made changes"
