#!/usr/bin/env sh

# Generate patch to add build script
# Just in case we've updated it
./generate_buildscript_patch.sh

# Build with Nix
command -v nix-build || echo 'Nix is not installed! Exiting.' && exit 1
nix-build --pure

# Output into build directory
mkdir -p build
cp -fv result/firmware.fd build/firmware.fd

# Validate build hash based on architecture
arch="$(uname -m)"

case "$arch" in
    "x86_64" | "amd64")
        echo '01b673bbb8e9bf7770b98fd2e8987c231b14a92367fe5988a975a43594ab25f2  build/firmware.fd' | sha256sum -c || echo 'Build does not match expected checksum!' && exit 2;;
    "aarch64" | "arm64")
        echo 'WIP';;
esac
