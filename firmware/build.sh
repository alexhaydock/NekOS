#!/usr/bin/env bash
set -euo pipefail

# Copy Secure Boot keys from sbkeys build
cp -fv ../sbkeys/keys/* keys/

# Download the upstream Tianocore build container Dockerfile
# We do this because they only build and push x86_64 versions upstream,
# but we want to support Apple Silicon, so we build it ourself locally
curl -o Dockerfile-buildenv https://raw.githubusercontent.com/tianocore/containers/refs/heads/main/Fedora-43/Dockerfile

# Remove the Powershell x86_64 install line from the Dockerfile
# as it won't work for us if we're on aarch64. We don't seem to
# actually need it just to do an OVMF firmware build
sed -i.bak '/PowerShell/ {/x86_64/d;}' Dockerfile-buildenv

# Build upstream Tianocore build container
podman build -f Dockerfile-buildenv --target build -t tianodev .

# Build OVMF firmware
podman build -t ovmf .

# Run container (debug version)
#podman run --rm -it --entrypoint bash ovmf

# Copy built firmware out of container
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ovmf -fv /opt/firmware.fd /opt/out/firmware.fd
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ovmf -fv /opt/OVMF_VARS_INSECURE.json /opt/out/OVMF_VARS_INSECURE.json
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ovmf -fv /opt/OVMF_VARS_MS.json /opt/out/OVMF_VARS_MS.json
podman run --rm -it -v "$(pwd)/build:/opt/out:Z" --entrypoint cp ovmf -fv /opt/OVMF_VARS_CUSTOM.json /opt/out/OVMF_VARS_CUSTOM.json
