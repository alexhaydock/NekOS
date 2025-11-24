#!/usr/bin/env bash
set -euo pipefail

# Copy Secure Boot keys from sbkeys build
cp -fv ../sbkeys/keys/* keys/

# Build OVMF firmware
podman build -t ovmf .

# Run container (debug version)
#podman run --rm -it --entrypoint bash ovmf

# Copy built firmware out of container
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ovmf -fv /opt/OVMF_CODE.fd /opt/out/OVMF_CODE.fd
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ovmf -fv /opt/OVMF_VARS_INSECURE.json /opt/out/OVMF_VARS_INSECURE.json
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ovmf -fv /opt/OVMF_VARS_MS.json /opt/out/OVMF_VARS_MS.json
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ovmf -fv /opt/OVMF_VARS_CUSTOM.json /opt/out/OVMF_VARS_CUSTOM.json
