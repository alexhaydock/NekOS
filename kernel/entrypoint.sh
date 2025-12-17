#!/usr/bin/env bash
set -euo pipefail

# Build with Nix using deterministic options
nix build --option sandbox true

# Hash output
sha256sum \
  /opt/nixbuild/result/kernel \
  /opt/nixbuild/result/kernelconfig-alpine \
  /opt/nixbuild/result/kernelconfig-nekos

# Copy output to mapped volume
cp -fv /opt/nixbuild/result/kernel /opt/out/kernel
cp -fv /opt/nixbuild/result/kernelconfig-alpine /opt/out/kernelconfig-alpine
cp -fv /opt/nixbuild/result/kernelconfig-nekos /opt/out/kernelconfig-nekos
