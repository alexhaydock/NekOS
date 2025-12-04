# Download and extract kernel tarball
FROM docker.io/library/alpine:3.23 as kerneldownloader

# Download the Alpine aports tree because we want to use
# the upstream linux-virt config as our base, and we
# might as well take the package version from the APKBUILD
# while we're at it
RUN apk --no-cache add git
RUN git clone --depth 1 https://git.alpinelinux.org/aports /opt/aports
WORKDIR /opt
# If the kernel version ends in .0 (i.e. just-released LTS)
# then we truncate it to remove the trailing .0 as that
# doesn't appear in the upstream URL used by kernel.org
RUN set -x && \
    export KERNVER="$(grep '^pkgver' /opt/aports/main/linux-lts/APKBUILD | cut -d'=' -f2)" && \
    case $KERNVER in *.0) KERNVER=${KERNVER%??} ;; esac && \
    echo "Building Linux ${KERNVER}..." && \
    wget --quiet "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNVER}.tar.xz" -O /opt/kernel.tar.xz && \
    tar xf /opt/kernel.tar.xz && \
    mv "/opt/linux-${KERNVER}" /opt/linux

# Start kernel build container
FROM docker.io/library/alpine:3.23 as kernelbuilder

# Standard Alpine SDK
RUN apk --no-cache add alpine-sdk
# makedepends from the linux-lts APKBUILD
RUN apk --no-cache add sed bc linux-headers linux-firmware-any openssl-dev mawk diffutils findutils zstd pahole python3 gcc
# _depends_dev from the linux-lts APKBUILD
RUN apk --no-cache add perl gmp-dev mpc1-dev mpfr-dev elfutils-dev bash flex bison zstd
# Add bash to run the scripts shipped in the kernel's scripts/ dir
RUN apk --no-cache add bash

# Copy kernel sources from download container
COPY --from=kerneldownloader /opt/linux/ /opt/linux/
WORKDIR /opt/linux

# Generate kernel config based on Alpine's upstream virt-lts kernel config
#
# Currently disabled since this config doesn't seem to include what we need
# to set up a full graphical environment, even when applying our overlay below
#
# Remember when I do come back to this, I need to use `uname -m` to retain
# Apple Silicon support
#COPY --from=kerneldownloader /opt/aports/main/linux-lts/virt.x86_64.config /opt/linux/.config
#RUN make olddefconfig

# Generate kernel config based on upstream defaults
RUN make defconfig

# Copy in kernel config fragments file to apply our own kernel config options
COPY features.config /opt/linux/features.config
RUN scripts/kconfig/merge_config.sh .config features.config

# Build kernel
RUN make -j"$(nproc)"

# Install modules into directory
RUN mkdir -p /opt/mod/lib/modules && \
    make modules_install \
        INSTALL_MOD_PATH="/opt/mod" \
        INSTALL_MOD_STRIP=1

# Copy whichever kernel file we actually built into /opt
RUN arch="$(uname -m)" && \
    case "$arch" in \
    x86_64 | amd64) \
      cp -fv /opt/linux/arch/x86/boot/bzImage /opt/kernel \
    ;; \
    aarch64 | arm64) \
      cp -fv /opt/linux/arch/arm64/boot/Image /opt/kernel \
    ;; \
    esac

# Final container that just contains our kernel and nothing more
FROM docker.io/library/alpine:3.23 as final
COPY --from=kernelbuilder /opt/kernel /opt/kernel
COPY --from=kernelbuilder /opt/mod /opt/mod
WORKDIR /opt
