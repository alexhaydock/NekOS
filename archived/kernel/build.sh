#!/usr/bin/env bash
set -euo pipefail

# Build kernel
podman build --target final -t kb .

# Run container (debug version)
#podman run --rm -it kb

# Run container to copy into output dir
podman run --rm -it \
  -v "$(pwd)/build:/opt/out:Z" \
  --entrypoint cp \
  kb \
  -fv /opt/kernel /opt/out/kernel

# Output the Alpine kernel config after a `make olddefconfig`
podman run --rm -it \
  -v "$(pwd)/build:/opt/out:Z" \
  --entrypoint cp \
  kb \
  -fv /opt/kernelconfig-alpine /opt/out/kernelconfig-alpine

# Output the upstream config from `make defconfig`
podman run --rm -it \
  -v "$(pwd)/build:/opt/out:Z" \
  --entrypoint cp \
  kb \
  -fv /opt/kernelconfig-default /opt/out/kernelconfig-default

# Output the final NekOS config we actually used
# (Alpine config plus our modifications)
podman run --rm -it \
  -v "$(pwd)/build:/opt/out:Z" \
  --entrypoint cp \
  kb \
  -fv /opt/kernelconfig-nekos /opt/out/kernelconfig-nekos

# echo reminder
echo ""
echo "Kernel built"
echo "Remember to rebuild the initramfs and UKI if you made changes"
