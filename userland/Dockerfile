# Container to build Toybox
FROM docker.io/library/alpine:3.23 as toybuild

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

RUN git clone --depth 1 https://github.com/landley/toybox.git /opt/toybox

WORKDIR /opt/toybox

# Generate default Toybox config
RUN make defconfig

# Add some of our own config options to build some of the
# experimental "toys"
#
# We particularly need modprobe since we're building with a
# config that uses kernel modules and without it we can't
# insert them
RUN sed -i 's/^# CONFIG_GETTY.*/CONFIG_GETTY=y/' .config && \
    sed -i 's/^# CONFIG_INIT.*/CONFIG_INIT=y/' .config && \
    sed -i 's/^# CONFIG_MODPROBE.*/CONFIG_MODPROBE=y/' .config && \
    sed -i 's/^# CONFIG_VI.*/CONFIG_VI=y/' .config

# Build Toybox
RUN make -j"$(nproc)"

# Create output dir
RUN mkdir -p /opt/toybox/fs

# Copy Toybox into output dir
RUN PREFIX=/opt/toybox/fs make install

# Create symlink between sbin/init and init, since the kernel
# expects to see our init at /init
WORKDIR /opt/toybox/fs
RUN ln -s sbin/init init

# Create some standard Linux FHS directories we'll need
RUN mkdir -p dev sys etc proc usr
RUN mkdir -p etc/init.d usr/share

# Add our init script into /etc/init.d
COPY rcS /opt/toybox/fs/etc/init.d/rcS
RUN chmod +x /opt/toybox/fs/etc/init.d/rcS

# Container to cheat a bit and copy some pre-built Alpine assets
# and dynamic libraries into the container
FROM docker.io/library/alpine:3.23 as dynamiclibs

# Install any deps we want to copy into our destination environment
RUN apk --no-cache add bash

# Copy our Toybox build so far
RUN mkdir -p /opt/toybox/fs
COPY --from=toybuild /opt/toybox/fs /opt/toybox/fs
WORKDIR /opt/toybox/fs

# Create lib directories
RUN mkdir -p /opt/toybox/fs/lib /opt/toybox/fs/usr/lib

# Cheat a bit and copy the host's bash into the environment, along
# with the dynamic libs from running `ldd /bin/bash`
#
# Note we copy it as /bin/sh as a cheap way of setting it as the
# default shell
RUN cp /bin/bash bin/sh
RUN for i in $(ldd /opt/toybox/fs/bin/sh | grep '=>' | awk '{print $3}'); do \
      cp -fv "${i}" "/opt/toybox/fs${i}"; \
    done

# Container to build wlroots as our graphical compositor
FROM docker.io/library/alpine:3.23 as wlroots

# Copy our Toybox build so far
RUN mkdir -p /opt/toybox/fs
COPY --from=dynamiclibs /opt/toybox/fs /opt/toybox/fs

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
RUN cp -fv /opt/wlroots/tinywl/tinywl /opt/toybox/fs/bin/

# Copy the dynamic libs needed for tinywl into our distro filesystem
#
# This is a little cheat where we use ldd and loop over the libs
# and copy them from our Alpine host
RUN for i in $(ldd /opt/toybox/fs/bin/tinywl | grep '=>' | awk '{print $3}'); do \
      cp -fv "${i}" "/opt/toybox/fs${i}"; \
    done

# Add seatd seat management daemon which is required by wlroots
# to run the compositor
#
# We cheat again here and directly unpack the Alpine binary build
# in the root of the initramfs, which puts everything from the
# package into the right directories
WORKDIR /opt/toybox/fs
RUN apk --no-cache fetch seatd && \
    tar xf seatd*.apk && \
    rm seatd*.apk
RUN apk --no-cache add seatd && \
    for i in $(ldd /opt/toybox/fs/usr/bin/seatd | grep '=>' | awk '{print $3}'); do \
      cp -fv "${i}" "/opt/toybox/fs${i}"; \
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
    for i in $(ldd /opt/toybox/fs/usr/bin/nyancat | grep '=>' | awk '{print $3}'); do \
      cp -fv "${i}" "/opt/toybox/fs${i}"; \
    done

# Add mokutil for testing Secure Boot is working
RUN apk --no-cache fetch mokutil && \
    tar xf mokutil*.apk && \
    rm mokutil*.apk
RUN apk --no-cache add mokutil && \
    for i in $(ldd /opt/toybox/fs/usr/bin/mokutil | grep '=>' | awk '{print $3}'); do \
      cp -fv "${i}" "/opt/toybox/fs${i}"; \
    done

# Add swayimg as our graphical image viewer
RUN apk --no-cache fetch swayimg && \
    tar xf swayimg*.apk && \
    rm swayimg*.apk
RUN apk --no-cache add swayimg && \
    for i in $(ldd /opt/toybox/fs/usr/bin/swayimg | grep '=>' | awk '{print $3}'); do \
      cp -fv "${i}" "/opt/toybox/fs${i}"; \
    done

# Add some images for viewing with swayimg
COPY cats/ /opt/toybox/fs/opt/cats/

# Create $XDG_RUNTIME_DIR for root which Wayland depends on
RUN mkdir -p /opt/toybox/fs/run/user/0
RUN echo 'export XDG_RUNTIME_DIR=/run/user/0' > /opt/toybox/fs/.bashrc
RUN chmod +x /opt/toybox/fs/.bashrc

# Borrow our keyboard keymaps etc from the Alpine host OS
RUN cp -rfv /usr/share/X11/ /opt/toybox/fs/usr/share/X11/

# Container to build our filesystem into an initramfs
FROM docker.io/library/alpine:3.23 as initramfs

# Install deps for initramfs building
RUN apk --no-cache add cpio

# Copy our Toybox build so far
RUN mkdir -p /opt/toybox/fs
COPY --from=wlroots /opt/toybox/fs /opt/toybox/fs

# Copy in our kernel modules from our kernel build container
# It's important that we've set CONFIG_MODULE_COMPRESS=n in our
# kernel config here, because the implementation of modprobe in
# Toybox doesn't seem to be built with gzip support
COPY --from=localhost/kb:latest /opt/mod/lib/modules /opt/toybox/fs/lib/modules

# Enter our Toybox dir and pack our initramfs
WORKDIR /opt/toybox/fs
RUN apk --no-cache add findutils && \
    find . | cpio -o -H newc > /opt/initramfs.cpio && \
    find . -type f -printf '%s %p\n' | sort -nr > /opt/initramfs.txt

# Final container that just contains our initramfs and nothing more
FROM docker.io/library/alpine:3.23
COPY --from=initramfs /opt/initramfs.cpio /opt/initramfs.cpio
COPY --from=initramfs /opt/initramfs.txt /opt/initramfs.txt
WORKDIR /opt
