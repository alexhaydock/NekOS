#!/usr/bin/env sh

# Generate patch to add build script
./generate_buildscript_patch.sh

# Build with Nix
nix-build --pure

# Output into build directory
mkdir -p build
cp -fv result/firmware.fd build/firmware.fd
