#!/usr/bin/env sh

# This test validates:
#   - OVMF firmware build
#   - Kernel build

# Copy VARS to temp location
cp -fv ../firmware/build/OVMF_VARS.fd /tmp/OVMF_VARS.fd

# Run with OVMF CODE and VARS
qemu-system-x86_64 \
  -m 2G \
  -machine q35,smm=off,vmport=off,accel=kvm \
  -kernel ../kernel/build/bzImage \
  -drive if=pflash,format=raw,unit=0,file=../firmware/build/OVMF_CODE.fd,readonly=on \
  -drive if=pflash,format=raw,unit=1,file=/tmp/OVMF_VARS.fd \
  -append "console=ttyS0" \
  -serial stdio
