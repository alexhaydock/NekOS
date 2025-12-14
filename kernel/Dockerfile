# Download and extract kernel tarball
FROM docker.io/library/alpine:3.23 as kerneldownloader

# Pin a specific kernel version for reproducibility
ENV KERNVER="6.18.1"

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
    case $KERNVER in *.0) KERNVER=${KERNVER%??} ;; esac && \
    echo "Building Linux ${KERNVER}..." && \
    wget --quiet \
      "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNVER}.tar.xz" \
      -O /opt/kernel.tar.xz && \
    tar xf /opt/kernel.tar.xz && \
    mv "/opt/linux-${KERNVER}" /opt/linux

# Start kernel build container
FROM docker.io/library/alpine:3.23 as kernelbuilder

# TODO: Migrate to Nix otherwise these
#       are non-deterministic as the
#       package versions aren't pinned
#
# Standard Alpine SDK
RUN apk --no-cache add \
    alpine-sdk
# makedepends from the linux-lts APKBUILD
RUN apk --no-cache add \
      bc \
      diffutils \
      findutils \
      gcc \
      linux-firmware-any \
      linux-headers \
      mawk \
      openssl-dev \
      pahole \
      python3 \
      sed \
      zstd
# _depends_dev from the linux-lts APKBUILD
RUN apk --no-cache add \
      bash \
      bison \
      elfutils-dev \
      flex \
      gmp-dev \
      mpc1-dev \
      mpfr-dev \
      perl \
      zstd

# Copy kernel sources from download container
COPY --from=kerneldownloader /opt/linux/ /opt/linux/
WORKDIR /opt/linux

# Introduce reproducibility before we start building anything
ENV KBUILD_BUILD_TIMESTAMP="1970-01-01 00:00:00 UTC"
ENV KBUILD_BUILD_USER="builder"
ENV KBUILD_BUILD_HOST="nekos"
ENV SOURCE_DATE_EPOCH=0
ENV KBUILD_ABS_SRCTREE=0
ENV GZIP=-n
ENV XZ_DEFAULTS="--threads=1 --no-adjust"
ENV LANG=C
ENV LC_ALL=C
ENV TZ=UTC
ENV KCFLAGS="-O2 -g -ffile-prefix-map=/opt/linux=. -fdebug-prefix-map=/opt/linux=."

# For debug purposes, generate a default config for this kernel and copy it
# (we immediately overwrite it in the next step with the Alpine config)
RUN make defconfig && \
    cp -fv /opt/linux/.config /opt/kernelconfig-default

# Generate kernel config based on Alpine's upstream virt-lts kernel config
COPY --from=kerneldownloader /opt/aports/main/linux-lts/virt.aarch64.config /opt/virt.aarch64.config
COPY --from=kerneldownloader /opt/aports/main/linux-lts/virt.x86_64.config /opt/virt.x86_64.config
RUN arch="$(uname -m)" && \
    case "$arch" in \
    x86_64 | amd64) \
      cp -fv /opt/virt.x86_64.config /opt/linux/.config \
    ;; \
    aarch64 | arm64) \
      cp -fv /opt/virt.aarch64.config /opt/linux/.config \
    ;; \
    esac && \
    make olddefconfig && \
    cp -fv /opt/linux/.config /opt/kernelconfig-alpine

# Disable modules as a big source of non-determinism
RUN scripts/config --disable MODULES && \
    make olddefconfig

# Standard other reproducibility options
RUN scripts/config --disable DEBUG_INFO && \
    scripts/config --disable IKCONFIG && \
    scripts/config --disable IKHEADERS && \
    scripts/config --disable STACK_VALIDATION && \
    scripts/config --disable GCC_PLUGINS && \
    scripts/config --disable SYSTEM_TRUSTED_KEYS && \
    scripts/config --disable SYSTEM_REVOCATION_KEYS && \
    make olddefconfig

# Ensure we actually have a VT (linux-virt is a bit conservative)
RUN scripts/config --enable CONFIG_TTY && \
    scripts/config --enable CONFIG_VT  && \
    scripts/config --enable CONFIG_VT_CONSOLE && \
    scripts/config --enable CONFIG_VT_HW_CONSOLE_BINDING && \
    scripts/config --enable CONFIG_DRM_FBDEV_EMULATION  && \
    scripts/config --enable CONFIG_FRAMEBUFFER_CONSOLE && \
    scripts/config --enable CONFIG_FRAMEBUFFER_CONSOLE_DETECT_PRIMARY && \
    make olddefconfig

# Enable/configure the things we need for NekOS
RUN scripts/config --enable CONFIG_DRM_BOCHS && \
    scripts/config --enable CONFIG_DRM_VIRTIO_GPU  && \
    scripts/config --enable CONFIG_LOGO && \
    scripts/config --set-str LOCALVERSION "-nekos" && \
    make olddefconfig

# Run make olddefconfig again just to make sure
# See: https://github.com/NixOS/nixpkgs/blob/09eb77e94fa25202af8f3e81ddc7353d9970ac1b/pkgs/os-specific/linux/kernel/generate-config.pl#L128-L132
RUN make olddefconfig && \
    cp -fv /opt/linux/.config /opt/kernelconfig-nekos

# Build kernel target (reproducibly)
RUN arch="$(uname -m)" && \
    case "$arch" in \
    x86_64 | amd64) \
      make -j1 KCFLAGS="$KCFLAGS" bzImage && \
      cp -fv /opt/linux/arch/x86/boot/bzImage /opt/kernel \
    ;; \
    aarch64 | arm64) \
      make -j1 KCFLAGS="$KCFLAGS" Image && \
      cp -fv /opt/linux/arch/arm64/boot/Image /opt/kernel \
    ;; \
    esac

# Final container that just contains our kernel and configs
FROM docker.io/library/alpine:3.23 as final
COPY --from=kernelbuilder /opt/kernel /opt/kernel
COPY --from=kernelbuilder /opt/kernelconfig-alpine /opt/kernelconfig-alpine
COPY --from=kernelbuilder /opt/kernelconfig-default /opt/kernelconfig-default
COPY --from=kernelbuilder /opt/kernelconfig-nekos /opt/kernelconfig-nekos
WORKDIR /opt

# Verify reproducibility for debug purposes
RUN sha256sum \
      /opt/kernel \
      /opt/kernelconfig-alpine \
      /opt/kernelconfig-default \
      /opt/kernelconfig-nekos
