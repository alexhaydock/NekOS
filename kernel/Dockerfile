# Download and extract kernel tarball
FROM docker.io/library/alpine:3.22 as kerneldownloader

# Download the Alpine aports tree because we want to use
# the upstream linux-virt config as our base, and we
# might as well take the package version from the APKBUILD
# while we're at it
RUN apk --no-cache add git
RUN git clone --depth 1 https://git.alpinelinux.org/aports /opt/aports
WORKDIR /opt
RUN export KERNVER="$(grep ^pkgver /opt/aports/main/linux-lts/APKBUILD | cut -d'=' -f2)" && \
    echo "Building Linux ${KERNVER}..." && \
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNVER}.tar.xz -O /opt/kernel.tar.xz && \
    tar xf /opt/kernel.tar.xz && \
    mv /opt/linux-${KERNVER} /opt/linux

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

# Copy kernel sources from download container
COPY --from=kerneldownloader /opt/linux/ /opt/linux/
WORKDIR /opt/linux

# Generate kernel config based on Alpine's upstream virt-lts kernel config
COPY --from=kerneldownloader /opt/aports/main/linux-lts/virt.x86_64.config /opt/linux/.config
RUN make olddefconfig

# Copy in kernel config fragments file to apply our own kernel config options
COPY features.config /opt/linux/features.config
RUN scripts/kconfig/merge_config.sh .config features.config

# Build kernel
RUN make -j$(nproc)

# Install modules into directory
RUN mkdir -p /opt/mod/lib/modules && \
    make modules_install \
        INSTALL_MOD_PATH="/opt/mod" \
        INSTALL_MOD_STRIP=1

# Final container that just contains our kernel and nothing more
FROM docker.io/library/alpine:3.22
COPY --from=kernelbuilder /opt/linux/arch/x86/boot/bzImage /opt/bzImage
COPY --from=kernelbuilder /opt/mod /opt/mod
WORKDIR /opt
