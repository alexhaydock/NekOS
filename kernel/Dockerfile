# Download and extract kernel tarball
FROM docker.io/library/alpine:3.22 as kerneldownloader
RUN mkdir /opt/download
WORKDIR /opt/download
ADD https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.58.tar.xz /opt/download/linux-6.12.58.tar.xz
RUN tar xf /opt/download/linux-6.12.58.tar.xz
RUN mv /opt/download/linux-6.12.58 /opt/download/linux

# Start kernel build container
FROM docker.io/library/alpine:3.22 as kernelbuilder

# Standard Alpine SDK
RUN apk add alpine-sdk
# makedepends from the linux-lts APKBUILD
RUN apk add sed bc linux-headers linux-firmware-any openssl-dev mawk diffutils findutils zstd pahole python3 gcc
# _depends_dev from the linux-lts APKBUILD
RUN apk add perl gmp-dev mpc1-dev mpfr-dev elfutils-dev bash flex bison zstd
# Add bash to run the scripts shipped in the kernel's scripts/ dir
RUN apk add bash

# Copy kernel sources and enter directory
COPY --from=kerneldownloader /opt/download/linux/ /opt/linux/
WORKDIR /opt/linux

# Configure the kernel to use the default upstream config
RUN make defconfig

# Copy in kernel config fragments file to apply it over our
# default config
COPY features.config /opt/linux/features.config
RUN scripts/kconfig/merge_config.sh .config features.config

# Build kernel
RUN make -j6

# Final container that just contains our kernel and nothing more
FROM docker.io/library/alpine:3.22
COPY --from=kernelbuilder /opt/linux/arch/x86/boot/bzImage /opt/bzImage
WORKDIR /opt
