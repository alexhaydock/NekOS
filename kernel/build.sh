#!/usr/bin/env bash
set -euo pipefail

# Build base container Nix
podman build -t kernelbuilder .

# Run build inside base container
#
# We do this differently to other stages since
# the Nix sandbox requires the use of --privileged
podman run --rm -it \
    --privileged \
    -v "$(pwd)/build:/opt/out:Z" \
    kernelbuilder

# Validate build hash based on architecture
#
# I attempted to do this using fixed-output derivations inside the Nix
# build itself, but seemingly changing the outputHash inside the Nix
# file changes the derivation hash, which ends up changing the resulting
# kernel hash. I can only assume that this is down to some build paths
# leaking into the final build somehow still, but I'm not 100% sure.
pytest -v ../tests/test_kernel.py
