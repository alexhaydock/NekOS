# Container to build BusyBox
FROM docker.io/library/alpine:3.23 as busybuild

# Determinism
ENV SOURCE_DATE_EPOCH=0
ENV LANG=C
ENV LC_ALL=C
ENV TZ=UTC
ENV CFLAGS="-O2 -g0 -ffile-prefix-map=/opt=/usr/src"
ENV LDFLAGS="-Wl,--build-id=none"

# See: https://github.com/tianon/dockerfiles/blob/master/toybox/Dockerfile
RUN apk --no-cache add \
    bash \
    cpio \
    findutils \
    gcc \
    git \
    linux-headers \
    make \
    musl-dev

RUN git clone --depth 1 https://git.busybox.net/busybox /opt/busybox

WORKDIR /opt/busybox

# Generate default BusyBox config
RUN make defconfig

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
RUN sed -i 's;^# CONFIG_STATIC is not set;CONFIG_STATIC=y;' .config && \
    sed -i 's;^CONFIG_TC=y;# CONFIG_TC is not set;' .config && \
    sed -i 's;^CONFIG_FEATURE_TC_INGRESS=y;# CONFIG_FEATURE_TC_INGRESS is not set;' .config && \
    sed -i 's;^CONFIG_PREFIX=.*;CONFIG_PREFIX="/opt/userland";' .config && \
    grep -E 'CONFIG_STATIC|CONFIG_TC|CONFIG_FEATURE_TC_INGRESS|CONFIG_PREFIX' .config

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
RUN apk --no-cache add wlroots && \
    apk info wlroots 2>/dev/null | head -n1 | awk '{print $1}' | cut -d'-' -f2 > /opt/wlver

# Download the source for the version of wlroots that matches what we've got from APK
WORKDIR /opt
RUN wget --quiet \
      "https://gitlab.freedesktop.org/wlroots/wlroots/-/archive/$(cat /opt/wlver)/wlroots-$(cat /opt/wlver).tar.gz" \
      -O /opt/wlroots.tar.gz && \
    tar xf /opt/wlroots.tar.gz && \
    rm -v /opt/wlroots.tar.gz && \
    mv -v "/opt/wlroots-$(cat /opt/wlver)" /opt/wlroots

# Build wlroots
# Based on: https://gitlab.freedesktop.org/wlroots/wlroots/-/blob/abf80b529e48823e21215a6ccc4653e2c2a4a565/.builds/alpine.yml
#
# REMOVED since we didn't actually use the whole wlroots
# build here -- we were just copying in tinywl which we
# can (and do) build independently below
#
#WORKDIR /opt/wlroots
#RUN apk --no-cache add \
#    alpine-sdk \
#    eudev-dev \
#    glslang \
#    lcms2-dev \
#    libdisplay-info-dev \
#    libinput-dev \
#    libliftoff-dev \
#    libxkbcommon-dev \
#    mesa-dev \
#    meson \
#    pixman-dev \
#    vulkan-headers \
#    vulkan-loader-dev \
#    wayland-dev \
#    wayland-protocols \
#    xcb-util-image-dev \
#    xcb-util-renderutil-dev \
#    xcb-util-wm-dev \
#    xwayland-dev \
#    libseat-dev \
#    hwdata-dev
#RUN meson setup build --fatal-meson-warnings --default-library=both -Dauto_features=enabled -Dxcb-errors=disabled --buildtype=debugoptimized
#RUN ninja -C build

# Build tinywl
# Based on: https://gitlab.freedesktop.org/wlroots/wlroots/-/blob/abf80b529e48823e21215a6ccc4653e2c2a4a565/tinywl/README.md
WORKDIR /opt/wlroots/tinywl
RUN apk --no-cache add \
    alpine-sdk \
    wayland-protocols \
    wlroots-dev
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
WORKDIR /opt/userland
RUN apk --no-cache fetch seatd && \
    tar xf seatd*.apk && \
    rm seatd*.apk
RUN apk --no-cache add seatd && \
    for i in $(ldd /opt/userland/usr/bin/seatd | grep '=>' | awk '{print $3}'); do \
      cp -fv "${i}" "/opt/userland${i}"; \
    done

# Add libudev-zero so we don't need to deal with setting up and
# running the libudev daemon
#
# This package only provides libs, so we don't need to worry
# about doing any ldd magic here
RUN apk --no-cache fetch libudev-zero && \
    tar xf libudev-zero*.apk && \
    rm libudev-zero*.apk

# Add nyancat for fun so we can test something that's non-graphical
# but which uses more complex ANSI escape sequences to paint colours
RUN apk --no-cache fetch nyancat && \
    tar xf nyancat*.apk && \
    rm nyancat*.apk
RUN apk --no-cache add nyancat && \
    for i in $(ldd /opt/userland/usr/bin/nyancat | grep '=>' | awk '{print $3}'); do \
      cp -fv "${i}" "/opt/userland${i}"; \
    done

# Add mokutil for testing Secure Boot is working
RUN apk --no-cache fetch mokutil && \
    tar xf mokutil*.apk && \
    rm mokutil*.apk
RUN apk --no-cache add mokutil && \
    for i in $(ldd /opt/userland/usr/bin/mokutil | grep '=>' | awk '{print $3}'); do \
      cp -fv "${i}" "/opt/userland${i}"; \
    done

# Add swayimg as our graphical image viewer
RUN apk --no-cache fetch swayimg && \
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
FROM docker.io/library/alpine:3.23 as initramfs

# Install deps for initramfs building
RUN apk --no-cache add cpio

# Copy our BusyBox build so far
RUN mkdir -p /opt/userland
COPY --from=busybuild /opt/userland /opt/userland

# Enter our BusyBox dir and pack our compressed initramfs
#
# Pipe through `sort -z `first to deterministically sort file output
# to help with reproducibility
#
# Also run gzip with the -n flag to avoid embedding timestamps
WORKDIR /opt/userland
RUN apk --no-cache add findutils && \
    find . -print0 | sort -z | cpio --null -o --format=newc > /opt/initramfs.cpio && \
    gzip -n < /opt/initramfs.cpio > /opt/initramfs && \
    find . -type f -printf '%s %p\n' | sort -nr > /opt/initramfs.txt

# Final container that just contains our gzipped initramfs and nothing more
FROM docker.io/library/alpine:3.23 as final
COPY --from=initramfs /opt/initramfs /opt/initramfs
COPY --from=initramfs /opt/initramfs.txt /opt/initramfs.txt
WORKDIR /opt
