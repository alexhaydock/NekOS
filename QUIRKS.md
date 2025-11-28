# Quirks

### CPU argument is required on aarch64
Without passing a `-cpu` argument, QEMU does not boot and fails silently. I think this is something to do with it needing to compile a devicetree to pass to the kernel (which we can manually do with `-dtb` if we like). Without a CPU type maybe it does nothing?
