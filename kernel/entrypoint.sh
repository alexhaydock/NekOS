#!/usr/bin/env bash
set -euo pipefail

# Build with Nix using deterministic options
nix-build --pure --option sandbox true --cores 1

# Hash output
sha256sum /opt/nixbuild/result/kernel

# Copy output to mapped volume
cp -fv /opt/nixbuild/result/kernel /opt/out/kernel
