#!/usr/bin/env bash
set -euo pipefail

# Build Toybox userland
podman build -t ul .

# Run container (debug version)
#podman run --rm -it ul

# Run container
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ul -fv /opt/initramfs.cpio /opt/out/initramfs
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ul -fv /opt/initramfs.txt /opt/out/initramfs_filelist.txt

# echo reminder
echo ""
echo "Userland built"
echo "Remember to rebuild the UKI if you made changes"
