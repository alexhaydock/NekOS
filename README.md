# NekOS

![NekOS Logo](logo.png)

An OS that only displays pictures of my cats.

It's fully Secure Boot signed with a custom keychain, and packed into a single [Unified Kernel Image](https://wiki.archlinux.org/title/Unified_kernel_image).

## Demo

<VIDEODEMO>

## Wait, what?
This is a research and development Linux distribution that I put together with the aim of learning more about the interaction between firmware, kernel, and low-level boot processes. To do this, it's helpful to have a "minimum viable product" distribution that I can control every aspect of. And why not make it do something at least vaguely interesting in the process?

I'm hoping to use this to research Verified Boot, Confidential Compute, and "Bring Your Own Firmware" type setups for physical-access threat models.

Current features:
* EDK II OVMF firmware for QEMU built from source
  * Built with support for [paravirtualised UEFI variables](https://www.qemu.org/docs/master/devel/uefi-vars.html#host-uefi-variable-service)
  * Built with Secure Boot support
* Multiple pre-populated UEFI variable stores:
  * Blank, with Secure Boot disabled
  * Secure Boot enabled and Microsoft keys enrolled
  * Secure Boot enabled and custom keys enrolled
* Linux kernel built from source
* Custom userland based on Toybox
* Kernel + userland packed into a Unified Kernel Image (UKI)
* UKI signed with a custom Secure Boot keychain

## Technical Architecture
```mermaid
flowchart LR
    fw[EDK II OVMF<br>Firmware] --> kernel[Linux<br>Kernel]
    subgraph Signed UKI Binary
        subgraph Toybox Userland
            init[Toybox<br>Init]
            init --> tinywl[tinywl<br>Compositor]
            tinywl --> swayimg[swayimg<br>Image Display]
        end
        kernel --> init
    end
```

## Build Instructions
I don't support this as a general tool, but if you want to base your own project on this then all of the code should be fairly easy to understnad as I've tried to comment it where possible.

To build and test this, you need `podman` and `qemu`.

Since this makes use of the QEMU [Host UEFI variable service](https://www.qemu.org/docs/master/devel/uefi-vars.html#host-uefi-variable-service), you will need at least QEMU 10 to make full use of this.

```sh
sudo dnf install -y podman qemu
```

```sh
./build-all.sh
```

To build any of the individual components, enter the directory for that component and run the build script:
```sh
./build.sh
```

## Running Tests
Since this is a R&D project, there's no real "production" deployment for this and all of the main functionality exists in the `tests/` directory.

The tests will launch QEMU with various elements of our OS loaded/enabled.

Current tests:

| Test | Notes |
|---|---|
| test-kernel.sh | Test only kernel. |
| test-kernel,initramfs.sh | Test kernel and initramfs (not packed into UKI). |
| test-fw,kernel.sh | Test firmware and kernel. |
| test-fw,kernel,initramfs.sh | Test firmware, kernel, and initramfs (not packed into UKI). |
| test-fw,kernel,initramfs,uki.sh | Test firmware, kernel, and initramfs (packed into UKI). |
| test-fw,kernel,initramfs,uki,sb-fail.sh | Test firmware, kernel, and initramfs (packed into UKI), with Microsoft Secure Boot keychain. It should **fail**. |
| test-fw,kernel,initramfs,uki,sb-pass.sh | Test firmware, kernel, and initramfs (packed into UKI), with our custom Secure Boot keychain. It should **pass**. |

## Future Plans
* GitHub Actions to automatically build + release a signed UKI for testing
* More validation / signing, including PCRs
* Secure Boot validation from inside OS
  * PCR signing validation from inside OS, using vTPM
* Reproducible firmware build with ability to pre-compute SEV hashes, allowing for Confidential Compute in BYOF environments
* Slimmer kernel config, removing unnecessary modules and bloat
* ISO build process, for booting this on real hardware
* And maybe more fun stuff in the userland? Who knows...

## License
Any code in this repo which is capable of being subject to copyright is licensed as per the LICENSE file in the root of this repository. This does not include the images of my cats.
