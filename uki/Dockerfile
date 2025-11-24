FROM docker.io/library/alpine:3.22

# Don't forget to build the kernel and initramfs before
# trying to combine them into a UKI
COPY src/bzImage /opt/bzImage
COPY src/initramfs /opt/initramfs

# Copy in our Secure Boot keys
COPY keys/ /opt/keys

# Add systemd-ukify and deps
RUN apk --no-cache add \
    sbsigntool \
    systemd-efistub \
    ukify

# Build signed UKI
RUN ukify build \
    --output "/opt/uki.efi" \
    --linux "/opt/bzImage" \
    --initrd "/opt/initramfs" \
    --secureboot-private-key="/opt/keys/db-priv.pem" \
    --secureboot-certificate="/opt/keys/db-cert.pem" \
    --sign-kernel
