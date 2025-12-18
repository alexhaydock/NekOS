# Container to build BusyBox
FROM docker.io/library/alpine:3.23 as busybuild

# Enter BusyBox version and sha256sum here
ARG BUSYVER="1.37.0"
ARG BUSYSHA="3311dff32e746499f4df0d5df04d7eb396382d7e108bb9250e7b519b837043a4"

# Enter Alpine package versions here
#
# TODO: This obviously isn't the cleanest method of
#       version-pinning and I probably want to do something
#       a bit more like StageX, but this does actually work...
#
# Pin these based on: https://pkgs.alpinelinux.org
ENV APK_ALPINE_SDK="1.1-r0"
ENV APK_BASH="5.3.3-r1"
ENV APK_CPIO="2.15-r0"
ENV APK_FINDUTILS="4.10.0-r0"
ENV APK_GCC="15.2.0-r2"
ENV APK_LIBUDEV_ZERO="1.0.3-r7"
ENV APK_LINUX_HEADERS="6.16.12-r0"
ENV APK_MAKE="4.4.1-r3"
ENV APK_MUSL_DEV="1.2.5-r21"
ENV APK_SEATD="0.9.1-r0"
ENV APK_SWAYIMG="4.6-r0"
ENV APK_WAYLAND_PROTOCOLS="1.46-r0"
ENV APK_WLROOTS="0.19.2-r0"

# Determinism
ENV CFLAGS="-O2 -g0 -ffile-prefix-map=/opt=/usr/src"
ENV KCONFIG_NOTIMESTAMP=1
ENV LANG=C
ENV LC_ALL=C
ENV LDFLAGS="-Wl,--build-id=none"
ENV SOURCE_DATE_EPOCH=0
ENV TZ=UTC

# See: https://github.com/tianon/dockerfiles/blob/master/toybox/Dockerfile
RUN apk --no-cache add \
    bash=${APK_BASH} \
    cpio=${APK_CPIO} \
    findutils=${APK_FINDUTILS} \
    gcc=${APK_GCC} \
    linux-headers=${APK_LINUX_HEADERS} \
    make=${APK_MAKE} \
    musl-dev=${APK_MUSL_DEV}

# Download BusyBox
#
# Seems a bit brittle because BusyBox's website is very slow
# and seems to sporadically break or take a long time to reply,
# but there's not much I can do as the source tarballs don't
# seem to have any obvious mirrors
RUN wget --quiet \
      https://busybox.net/downloads/busybox-${BUSYVER}.tar.bz2 \
      -O /opt/busybox.tar.bz2 && \
    if ! echo "${BUSYSHA}  /opt/busybox.tar.bz2" | sha256sum -c; then \
        echo 'Build does not match expected checksum!' && exit 1; \
    else \
        echo 'Build matches expected checksum!'; \
    fi && \
    tar xf /opt/busybox.tar.bz2 -C /opt && \
    mv -fv /opt/busybox-${BUSYVER} /opt/busybox

# Build BusyBox as a static binary, and set some options.
#
# Previously I used Toybox here but it seems a little easier to
# build BusyBox statically and not worry about libraries.
#
# For Toybox we needed to enable CONFIG_INIT and CONFIG_MODPROBE
# here to allow it to be used as the init system, and to insert
# kernel modules, but it seems like those are defaults for BusyBox.
#
# We disable tc here due to BusyBox's tc code still relying on
# CBQ which was removed in Linux 6.8 and otherwise causes build
# failures.
#
# We need to hardcode the destination directory that `make install`
# will later use here for some reason, in the CONFIG_PREFIX var.
#
# Heavily inspired by StageX's deterministic BusyBox build:
# See: https://codeberg.org/stagex/stagex/src/commit/4a9058f6cc16dc81f762543d768176762b600dd7/packages/core/busybox/Containerfile
WORKDIR /opt/busybox
RUN <<EOF
  set -eux
  setConfs='
      CONFIG_LAST_SUPPORTED_WCHAR=0
      CONFIG_PREFIX="/opt/userland"
      CONFIG_STATIC=y
  '
  unsetConfs='
      CONFIG_FEATURE_HAVE_RPC
      CONFIG_FEATURE_INETD_RPC
      CONFIG_FEATURE_SYNC_FANCY
      CONFIG_FEATURE_TC_INGRESS
      CONFIG_FEATURE_UTMP
      CONFIG_FEATURE_WTMP
      CONFIG_SHA1_HWACCEL
      CONFIG_TC
  '
  make defconfig
  for conf in $unsetConfs; do
    sed -i \
      -e "s!^$conf=.*\$!# $conf is not set!" \
    .config
  done
  for confV in $setConfs; do
    conf="${confV%=*}"
    sed -i \
      -e "s!^$conf=.*\$!$confV!" \
      -e "s!^# $conf is not set\$!$confV!" \
      .config
    if ! grep -q "^$confV\$" .config; then
      echo "$confV" >> .config
    fi
  done
  make oldconfig
  for conf in $unsetConfs; do
    ! grep -q "^$conf=" .config
  done
  for confV in $setConfs; do
    grep -q "^$confV\$" .config
  done
EOF

# Build BusyBox
RUN make -j"$(nproc)"

# Create a directory to put our userland in
RUN mkdir -p /opt/userland

# Create some standard Linux FHS directories we'll need
RUN mkdir -p \
      /opt/userland/bin \
      /opt/userland/dev \
      /opt/userland/etc/init.d \
      /opt/userland/lib \
      /opt/userland/proc \
      /opt/userland/sbin \
      /opt/userland/sys \
      /opt/userland/tmp \
      /opt/userland/usr/bin \
      /opt/userland/usr/lib \
      /opt/userland/usr/sbin \
      /opt/userland/usr/share

# Install BusyBox into output dir
#
# This will also set up the symlinks to the static
# BusyBox binary for us
#
# Unlike Toybox, we don't need to create
# a symlink to /sbin/init since BusyBox will also
# do that for us
RUN make install

# Add our init script
COPY init /opt/userland/init
RUN chmod +x /opt/userland/init

# Discover the version of wlroots that this release of Alpine is shipping
# (lazily, by installing the package)
RUN apk --no-cache add \
      wlroots=${APK_WLROOTS} && \
    apk info wlroots 2>/dev/null | head -n1 | awk '{print $1}' | cut -d'-' -f2 > /opt/wlver

# Download the source for the version of wlroots that matches what we've got from APK
WORKDIR /opt
RUN wget --quiet \
      "https://gitlab.freedesktop.org/wlroots/wlroots/-/archive/$(cat /opt/wlver)/wlroots-$(cat /opt/wlver).tar.gz" \
      -O /opt/wlroots.tar.gz && \
    tar xf /opt/wlroots.tar.gz && \
    rm -v /opt/wlroots.tar.gz && \
    mv -v "/opt/wlroots-$(cat /opt/wlver)" /opt/wlroots

# Build tinywl
# Based on: https://gitlab.freedesktop.org/wlroots/wlroots/-/blob/abf80b529e48823e21215a6ccc4653e2c2a4a565/tinywl/README.md
WORKDIR /opt/wlroots/tinywl
RUN apk --no-cache add \
    alpine-sdk=${APK_ALPINE_SDK} \
    wayland-protocols=${APK_WAYLAND_PROTOCOLS} \
    wlroots-dev=${APK_WLROOTS}
RUN make

# Copy the tinywl compositor into our distro filesystem
RUN cp -fv /opt/wlroots/tinywl/tinywl /opt/userland/bin/

# Copy the dynamic libs needed for tinywl into our distro filesystem
#
# This is a little cheat where we use ldd and loop over the libs
# and copy them from our Alpine host
RUN for i in $(ldd /opt/userland/bin/tinywl | grep '=>' | awk '{print $3}'); do \
      cp -fv "${i}" "/opt/userland${i}"; \
    done

# Add seatd seat management daemon which is required by wlroots
# to run the compositor
#
# We cheat again here and directly unpack the Alpine binary build
# in the root of the initramfs, which puts everything from the
# package into the right directories
#
# TODO: Invocations of apk fetch need to use --recursive for some
#       reason, due to this bug:
#       https://gitlab.alpinelinux.org/alpine/apk-tools/-/merge_requests/281#note_522820
WORKDIR /opt/userland
RUN apk --no-cache fetch --recursive \
      seatd=${APK_SEATD} && \
    tar xf seatd*.apk && \
    rm seatd*.apk
RUN apk --no-cache add \
      seatd=${APK_SEATD} && \
    for i in $(ldd /opt/userland/usr/bin/seatd | grep '=>' | awk '{print $3}'); do \
      cp -fv "${i}" "/opt/userland${i}"; \
    done

# Add libudev-zero so we don't need to deal with setting up and
# running the libudev daemon
#
# This package only provides libs, so we don't need to worry
# about doing any ldd magic here
RUN apk --no-cache fetch --recursive \
      libudev-zero=${APK_LIBUDEV_ZERO} && \
    tar xf libudev-zero*.apk && \
    rm libudev-zero*.apk

# Add swayimg as our graphical image viewer
RUN apk --no-cache fetch --recursive \
      swayimg=${APK_SWAYIMG} && \
    tar xf swayimg*.apk && \
    rm swayimg*.apk
RUN apk --no-cache add swayimg && \
    for i in $(ldd /opt/userland/usr/bin/swayimg | grep '=>' | awk '{print $3}'); do \
      cp -fv "${i}" "/opt/userland${i}"; \
    done

# Add some images for viewing with swayimg
COPY cats/ /opt/userland/opt/cats/

# Create $XDG_RUNTIME_DIR for root which Wayland depends on
RUN mkdir -p /opt/userland/run/user/0
RUN echo 'export XDG_RUNTIME_DIR=/run/user/0' > /opt/userland/.bashrc
RUN chmod +x /opt/userland/.bashrc

# Borrow our keyboard keymaps etc from the Alpine host OS
RUN cp -rfv /usr/share/X11/ /opt/userland/usr/share/X11/

# Container to build our filesystem into an initramfs
FROM busybuild as initramfs

# Install deps for initramfs building
RUN apk --no-cache add \
      cpio=${APK_CPIO}

# Copy our BusyBox build so far
RUN mkdir -p /opt/userland
COPY --from=busybuild /opt/userland /opt/userland

# Enter our BusyBox dir and pack our compressed initramfs
#
# Based on StageX's example initramfs build as part of the
# demo "ReprOS" project:
# https://codeberg.org/stagex/repros/src/commit/eee4c999efd13fe51c29d009bf0ea1abe049892a/src/guest/Containerfile#L82-L100
RUN find . -exec touch -hcd "@0" "{}" + && \
    find . -print0 \
    | sort -z \
    | cpio \
        --null \
        --create \
        --verbose \
        --reproducible \
        --format=newc \
    | gzip --best \
    > /opt/initramfs && \
    find . -type f -printf '%s %p\n' | sort -nr > /opt/initramfs.txt

# Final container that just contains our gzipped initramfs and nothing more
FROM docker.io/library/alpine:3.23 as final
COPY --from=initramfs /opt/initramfs /opt/initramfs
COPY --from=initramfs /opt/initramfs.txt /opt/initramfs.txt
WORKDIR /opt
