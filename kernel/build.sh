#!/usr/bin/env bash
set -euo pipefail

# Build kernel
podman build --target final -t kb .

# Run container (debug version)
#podman run --rm -it kb

# Run container to copy kernel into output dir
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp kb -fv /opt/kernel /opt/out/kernel

# echo reminder
echo ""
echo "Kernel built"
echo "Remember to rebuild the initramfs and UKI if you made changes"
