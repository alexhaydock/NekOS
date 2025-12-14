# Download and extract kernel tarball
FROM docker.io/library/alpine:3.23 as kerneldownloader

# Pin a specific kernel version for reproducibility
ENV KERNVER="6.18.1"

# If the kernel version ends in .0 (i.e. just-released LTS)
# then we truncate it to remove the trailing .0 as that
# doesn't appear in the upstream URL used by kernel.org
WORKDIR /opt
RUN set -x && \
    case $KERNVER in *.0) KERNVER=${KERNVER%??} ;; esac && \
    echo "Downloading Linux ${KERNVER}..." && \
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
    cp -fv /opt/linux/.config /opt/kernelconfig-default && \
    rm -v .config

# Add the commit hash of the upstream Alpine aports repo that we're pinning to
# for fetching the linux-virt kernel config we're going to use as our base
ENV ALPINE_APORTS_HASH="2723fe77237cedef8130eaf4d3da4ff8ad5b3278"

# Download appropriate Alpine linux-virt kernel config for our arch
# (and copy it elsewhere before doing further things to it, for debug
# purposes if we need to do comparisons later)
RUN arch="$(uname -m)" && \
    case "$arch" in \
    x86_64 | amd64) \
      wget --quiet \
        "https://gitlab.alpinelinux.org/alpine/aports/-/raw/${ALPINE_APORTS_HASH}/main/linux-lts/virt.x86_64.config" \
        -O /opt/linux/.config \
    ;; \
    aarch64 | arm64) \
      wget --quiet \
        "https://gitlab.alpinelinux.org/alpine/aports/-/raw/${ALPINE_APORTS_HASH}/main/linux-lts/virt.aarch64.config" \
        -O /opt/linux/.config \
    ;; \
    esac && \
    make olddefconfig && \
    cp -fv /opt/linux/.config /opt/kernelconfig-alpine

# Disable modules as a big source of non-determinism
RUN scripts/config --disable MODULES && \
    make olddefconfig

# Disable a bunch of other flags to make things more reproducible
RUN scripts/config --disable DEBUG_INFO && \
    scripts/config --disable GCC_PLUGINS && \
    scripts/config --disable IKCONFIG && \
    scripts/config --disable IKHEADERS && \
    scripts/config --disable STACK_VALIDATION && \
    scripts/config --disable SYSTEM_REVOCATION_KEYS && \
    scripts/config --disable SYSTEM_TRUSTED_KEYS && \
    make olddefconfig

# Enable/configure some tweaks for NekOS
RUN scripts/config --enable CONFIG_LOGO && \
    scripts/config --set-str CONFIG_DEFAULT_HOSTNAME "nekos" && \
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
