FROM docker.io/library/alpine:3.23 as final

# Add systemd-ukify and deps
RUN apk --no-cache add \
    sbsigntool \
    systemd-efistub \
    ukify

# Don't forget to build the kernel and initramfs before
# trying to combine them into a UKI
COPY src/kernel /opt/kernel
COPY src/initramfs /opt/initramfs

# Copy in our Secure Boot keys
COPY keys/ /opt/keys

# Build unsigned UKI
#
# IMPORTANT, as this is the one we'll validate for
# reproducibility purposes
RUN ukify build \
    --output "/opt/uki.efi" \
    --linux "/opt/kernel" \
    --initrd "/opt/initramfs"

# Build signed UKI
RUN ukify build \
    --output "/opt/uki.signed.efi" \
    --linux "/opt/kernel" \
    --initrd "/opt/initramfs" \
    --secureboot-private-key="/opt/keys/db-priv.pem" \
    --secureboot-certificate="/opt/keys/db-cert.pem" \
    --sign-kernel

# Validate UKI to make sure signing succeeded
RUN sbverify \
    --cert /opt/keys/db-cert.pem \
    /opt/uki.signed.efi
