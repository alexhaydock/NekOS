#!/usr/bin/env bash
set -euo pipefail

# Copy Secure Boot keys from keygen build
cp -fv ../keygen/keys/* keys/

# Generate EFI Vars
podman build --target final -t efivars .

# Run container (debug version)
#podman run --rm -it --entrypoint bash efivars

# Copy built firmware out of container
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp efivars -fv /opt/OVMF_VARS_INSECURE.json /opt/out/OVMF_VARS_INSECURE.json
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp efivars -fv /opt/OVMF_VARS_MS.json /opt/out/OVMF_VARS_MS.json
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp efivars -fv /opt/OVMF_VARS_CUSTOM.json /opt/out/OVMF_VARS_CUSTOM.json
