#!/usr/bin/env bash
set -euo pipefail

# Build with Nix using deterministic options
nix build --option sandbox true

# Hash output
sha256sum /opt/nixbuild/result/firmware.fd

# Copy output to mapped volume
cp -fv /opt/nixbuild/result/firmware.fd /opt/out/firmware.fd
