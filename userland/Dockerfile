# Container to build Toybox
FROM docker.io/library/alpine:3.22 as toybuild

# See: https://github.com/tianon/dockerfiles/blob/master/toybox/Dockerfile
RUN apk add --no-cache \
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
RUN sed -i 's/^# CONFIG_GETTY.*/CONFIG_GETTY=y/' .config && \
    sed -i 's/^# CONFIG_INIT.*/CONFIG_INIT=y/' .config && \
    sed -i 's/^# CONFIG_VI.*/CONFIG_VI=y/' .config

# Build Toybox
RUN make -j6

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
FROM docker.io/library/alpine:3.22 as dynamiclibs

# Install any deps we want to copy into our destination environment
RUN apk add bash

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
RUN for i in $(ldd /opt/toybox/fs/bin/sh | grep '=>' | awk '{print $3}'); do cp -fv ${i} /opt/toybox/fs${i}; done

# Container to build wlroots as our graphical compositor
FROM docker.io/library/alpine:3.22 as wlroots

# Copy our Toybox build so far
RUN mkdir -p /opt/toybox/fs
COPY --from=dynamiclibs /opt/toybox/fs /opt/toybox/fs

# Add wlroots build deps
RUN apk --no-cache add \
    alpine-sdk \
    eudev-dev \
    hwdata-dev \
    libdisplay-info-dev \
    libdrm-dev \
    libinput-dev \
    libseat-dev \
    libxkbcommon-dev \
    meson \
    pixman-dev \
    wayland-dev \
    wayland-protocols-dev \
    wlroots

# Discover the version of wlroots we have from APK on our build host
RUN apk info wlroots 2>/dev/null | head -n1 | awk '{print $1}' | cut -d'-' -f2 > /opt/wlver

# Download the source for the version of wlroots that matches what we've got from APK
WORKDIR /opt
RUN wget https://gitlab.freedesktop.org/wlroots/wlroots/-/archive/$(cat /opt/wlver)/wlroots-$(cat /opt/wlver).tar.gz -O /opt/wlroots.tar.gz
RUN tar xf /opt/wlroots.tar.gz
RUN rm -v /opt/wlroots.tar.gz
RUN mv -v /opt/wlroots-$(cat /opt/wlver) /opt/wlroots

# Enter the wlroots dir
WORKDIR /opt/wlroots

# Build wlroots
RUN meson setup build
RUN ninja -C build

# Copy the tinywl compositor into our distro filesystem
RUN cp -fv /opt/wlroots/build/tinywl/tinywl /opt/toybox/fs/bin/

# Copy the dynamic libs needed for tinywl into our distro filesystem
#
# This is a little cheat where we use ldd and loop over the libs
# and copy them from our Alpine host
RUN for i in $(ldd /opt/toybox/fs/bin/tinywl | grep '=>' | awk '{print $3}'); do cp -fv ${i} /opt/toybox/fs${i}; done

# Copy example into distro fs including libs if needed
RUN cp -fv /opt/wlroots/build/examples/simple /opt/toybox/fs/bin/
RUN for i in $(ldd /opt/toybox/fs/bin/simple | grep '=>' | awk '{print $3}'); do cp -fv ${i} /opt/toybox/fs${i}; done

# Add seatd seat management daemon which is required by wlroots
# to run the compositor
#
# We cheat again here and directly unpack the Alpine binary build
# in the root of the initramfs, which puts everything from the
# package into the right directories
WORKDIR /opt/toybox/fs
RUN apk --no-cache fetch seatd
RUN tar xf seatd*.apk
RUN rm seatd*.apk

# Add libudev-zero so we don't need to deal with setting up and
# running the libudev daemon
RUN apk --no-cache fetch libudev-zero
RUN tar xf libudev-zero*.apk
RUN rm libudev-zero*.apk

# Add nyancat for fun so we can test something that's non-graphical
# but which uses more complex ANSI escape sequences to paint colours
RUN apk --no-cache fetch nyancat
RUN tar xf nyancat*.apk
RUN rm nyancat*.apk

# Add swayimg as our graphical image viewer, along with the required libs
RUN apk --no-cache fetch swayimg
RUN tar xf swayimg*.apk
RUN rm swayimg*.apk

# Install swayimg into the container so the dependencies get resolved
# and we have all the dynamic libs needed to copy into the initramfs
RUN apk --no-cache add swayimg
RUN for i in $(ldd /opt/toybox/fs/usr/bin/swayimg | grep '=>' | awk '{print $3}'); do cp -fv ${i} /opt/toybox/fs${i}; done

# Add some images for viewing with swayimg
COPY cats/ /opt/toybox/fs/opt/cats/

# Create $XDG_RUNTIME_DIR for root which Wayland depends on
RUN mkdir -p /opt/toybox/fs/run/user/0
RUN echo 'export XDG_RUNTIME_DIR=/run/user/0' > /opt/toybox/fs/.bashrc
RUN chmod +x /opt/toybox/fs/.bashrc

# Borrow our keyboard keymaps etc from the Alpine host OS
RUN cp -rfv /usr/share/X11/ /opt/toybox/fs/usr/share/X11/

# Container to build our filesystem into an initramfs
FROM docker.io/library/alpine:3.22 as initramfs

# Install deps for initramfs building
RUN apk add cpio

# Copy our Toybox build so far
RUN mkdir -p /opt/toybox/fs
COPY --from=wlroots /opt/toybox/fs /opt/toybox/fs

# Enter our Toybox dir and pack our initramfs
WORKDIR /opt/toybox/fs
RUN find | cpio -o -H newc > /opt/initramfs.cpio

# Final container that just contains our initramfs and nothing more
FROM docker.io/library/alpine:3.22
COPY --from=initramfs /opt/initramfs.cpio /opt/initramfs.cpio
WORKDIR /opt
