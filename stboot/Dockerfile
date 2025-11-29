FROM docker.io/library/golang:alpine as stbootuki

# Deps based on this list:
# https://docs.system-transparency.org/st-1.3.0/docs/introduction/build/
RUN apk --no-cache add \
    bash \
    ca-certificates \
    coreutils \
    cpio \
    git \
    go \
    pigz

# Don't forget to build the kernel and initramfs before
# trying to combine them into a UKI
COPY src/kernel /opt/kernel
COPY src/initramfs /opt/initramfs

# Copy in our Secure Boot keys
COPY keys/ /opt/keys

# Install stmgr
RUN go install system-transparency.org/stmgr@v0.6.6

# Clone stimages which has the scripts to build
# our stboot bootloader
RUN git clone \
    -b stimages-0.1.3 \
    --depth 1 \
    https://git.glasklar.is/system-transparency/core/stimages.git \
    /opt/stimages

# WIP: Generate new signing keys here (move to sbkeys step)
# Import our signing keys
RUN mkdir keys
WORKDIR /opt/stimages/keys
RUN stmgr keygen certificate --isCA && \
    stmgr keygen certificate \
    --rootCert rootcert.pem \
    --rootKey rootkey.pem

# Build stboot UKI, embedding the public key that
# we're going to sign our OS package with, and the
# URL that we're going to boot the OS package from
WORKDIR /opt/stimages
RUN /opt/stimages/contrib/stboot/build-stboot \
    http://10.0.2.2:8000/nekos.json \
    keys/rootcert.pem \
    uki

# Build OS image with ospkg create
RUN stmgr ospkg create \
    --label="NekOS" \
    --initramfs=/opt/initramfs \
    --kernel=/opt/kernel \
    --url=http://10.0.2.2:8000/nekos.zip \
    --out=nekos.zip

# Sign OS package
RUN stmgr ospkg sign \
    --cert keys/cert.pem \
    --key keys/key.pem \
    --ospkg nekos

# Final container that just contains our stboot UKI, OS image, and JSON manifest
FROM docker.io/library/alpine:edge
COPY --from=stbootuki /opt/stimages/stboot.uki /opt/stboot.uki
COPY --from=stbootuki /opt/stimages/nekos.json /opt/nekos.json
COPY --from=stbootuki /opt/stimages/nekos.zip /opt/nekos.zip
WORKDIR /opt
