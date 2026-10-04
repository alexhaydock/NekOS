#!/usr/bin/env bash
set -euo pipefail

# Label group for CI
echo "::group::Building EDK2 firmware"
trap 'echo "::endgroup::"' EXIT

# Build base container Nix
podman build -t firmwarebuilder .

# Run build inside base container
#
# We do this differently to other stages since
# the Nix sandbox requires the use of --privileged
podman run --rm -it \
    --privileged \
    -v "$(pwd)/build:/opt/out:Z" \
    firmwarebuilder

# Validate build hash based on architecture
(
    cd ..
    podman run --rm -it \
        --workdir /opt \
        -v "$(pwd):/opt:Z" \
        docker.io/library/python:3-slim \
            bash -c 'pip install pytest && pytest -v tests/test_firmware.py'
)
