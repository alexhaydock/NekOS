#!/usr/bin/env bash
set -euo pipefail

# Build kernel
podman build -t kb .

# Run container to copy kernel into output dir
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp kb -fv /opt/bzImage /opt/out/bzImage

# echo reminder
echo ""
echo "Kernel built"
echo "Remember to rebuild the UKI if you made changes"
