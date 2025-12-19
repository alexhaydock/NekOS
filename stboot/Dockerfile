FROM docker.io/library/golang:alpine as stbootuki

# Deps based on this list:
# https://docs.system-transparency.org/st-1.3.0/docs/introduction/build/
RUN apk --no-cache add \
    bash \
    binutils \
    ca-certificates \
    coreutils \
    cpio \
    git \
    pigz \
    sbsigntool

# Don't forget to build the kernel and initramfs before
# trying to combine them into a UKI
COPY src/kernel /opt/kernel
COPY src/initramfs /opt/initramfs

# Install stmgr
RUN go install system-transparency.org/stmgr@v0.6.6

# Clone stimages which has the scripts to build
# our stboot bootloader
RUN git clone \
    -b stimages-0.1.3 \
    --depth 1 \
    https://git.glasklar.is/system-transparency/core/stimages.git \
    /opt/stimages

# Import our signing keys
#
# This imports both the Secure Boot and stboot keys
# which is important since we need to embed our stboot
# pubkey into the stboot UKI, but we also want to sign
# the resulting UKI with the Secure Boot keys so we
# can validate the boot chain.
COPY keys/ /opt/stimages/keys

# Build stboot UKI, embedding the public key that
# we're going to sign our OS package with, and the
# URL that we're going to boot the OS package from
WORKDIR /opt/stimages
RUN /opt/stimages/contrib/stboot/build-stboot \
    http://10.0.2.2:8000/nekos.json \
    keys/rootcert.pem \
    uki && \
    mv -fv /opt/stimages/stboot.uki /opt/stimages/stboot.efi

# Sign stboot UKI (with Secure Boot keys)
RUN sbsign \
    --key /opt/stimages/keys/db-priv.pem \
    --cert /opt/stimages/keys/db-cert.pem \
    --output /opt/stimages/stboot.signed.efi \
    /opt/stimages/stboot.efi

# Validate UKI to make sure signing succeeded
RUN sbverify \
    --cert /opt/stimages/keys/db-cert.pem \
    /opt/stimages/stboot.signed.efi

# Build OS image with ospkg create
#
# Make a copy so we have preserved this before we
# make it non-reproducible by signing it
RUN stmgr ospkg create \
    --label="NekOS" \
    --initramfs=/opt/initramfs \
    --kernel=/opt/kernel \
    --url=http://10.0.2.2:8000/nekos.signed.zip \
    --out=nekos.zip && \
    cp -fv /opt/stimages/nekos.zip /opt/stimages/nekos.unsigned.zip

# Sign nekos.zip package (with stboot keys)
RUN stmgr ospkg sign \
    --cert keys/cert.pem \
    --key keys/key.pem \
    --ospkg nekos

# Final container that just contains our stboot UKI,
# OS image, and JSON manifest
FROM docker.io/library/alpine:3.23 as final
COPY --from=stbootuki /opt/stimages/stboot.efi /opt/stboot.efi
COPY --from=stbootuki /opt/stimages/stboot.signed.efi /opt/stboot.signed.efi
COPY --from=stbootuki /opt/stimages/nekos.json /opt/nekos.json

# Copy stboot ZIP files so they match the naming
# scheme we're using for the kernel and UKI
# (where the signed image has ".signed." in the 
# filename)
COPY --from=stbootuki /opt/stimages/nekos.zip /opt/nekos.signed.zip
COPY --from=stbootuki /opt/stimages/nekos.unsigned.zip /opt/nekos.zip

WORKDIR /opt
