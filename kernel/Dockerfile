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
    make olddefconfig

# Copy in kernel config fragments file to apply our own kernel config options
COPY features.config /opt/linux/features.config
RUN scripts/kconfig/merge_config.sh .config features.config

# Run make olddefconfig again a few times just to make sure
# See: https://github.com/NixOS/nixpkgs/blob/09eb77e94fa25202af8f3e81ddc7353d9970ac1b/pkgs/os-specific/linux/kernel/generate-config.pl#L128-L132
RUN make olddefconfig && \
    make olddefconfig

# Build kernel (reproducibly)
RUN make -j1 KCFLAGS="$KCFLAGS"

# Install modules into directory
RUN mkdir -p /opt/mod/lib/modules && \
    make -j1 \
      INSTALL_MOD_PATH="/opt/mod" \
      INSTALL_MOD_STRIP=1 \
      KCFLAGS="$KCFLAGS" \
      modules_install

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

# Verify reproducibility for debug purposes
RUN sha256sum /opt/kernel && \
    sha256sum -r /opt/mod/*
