#!/usr/bin/env sh

# This test validates:
#   - OVMF firmware build
#   - Kernel build
#   - Initramfs build
#   - UKI build
#   - Secure Boot (using custom keys, which should pass)

# Copy Secure Boot VARS with our custom keys to temp location
cp -fv ../firmware/build/OVMF_VARS_CUSTOM.json /tmp/OVMF_VARS_CUSTOM.json

# Run with custom OVMF CODE and custom VARS which contain
# our custom Secure Boot key signing chain
#
# We also specifically need to boot the UKI here since
# otherwise QEMU doesn't fully validate the Secure Boot
# state (it flashes a warning that passing the kernel
# directly is insecure)
qemu-system-x86_64 \
  -m 2G \
  -machine q35,smm=off,vmport=off,accel=kvm \
  -kernel ../uki/build/uki.efi \
  -drive if=pflash,format=raw,unit=0,file=../firmware/build/OVMF_CODE.fd,readonly=on \
  -device uefi-vars-x64,jsonfile=/tmp/OVMF_VARS_CUSTOM.json
