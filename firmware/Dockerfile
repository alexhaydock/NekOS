# Use the Tianocore upstream development container
# See build.sh for how we build this
FROM localhost/tianodev as builder

# Set a version to use
ENV VERSION=202511

# Check out edk2 upstream repository
RUN git clone --branch edk2-stable$VERSION --depth 1 https://github.com/tianocore/edk2.git /opt/edk2
WORKDIR /opt/edk2
RUN git submodule update --init --recursive --depth 1

# Copy custom logo into the firmware build
COPY logo.png /opt/logo.png
RUN dnf install -y ImageMagick
# Convert logo to a BMP with a black background and put
# it into the right place
RUN magick \
        /opt/logo.png \
        -background black \
        -alpha remove \
        -define bmp:format=mbp3 \
        /opt/edk2/MdeModulePkg/Logo/Logo.bmp

# Build OVMF CODE with support for Secure Boot, TPM, and
# paravirtualised UEFI vars
# (based on the build() function from the Alpine APKBUILD)
RUN arch="$(uname -m)" && \
    case "$arch" in \
    x86_64 | amd64) \
      export TARGET_ARCH="X64" && \
      export PLATFORM="OvmfPkg/OvmfPkgX64.dsc" \
    ;; \
    aarch64 | arm64) \
      export TARGET_ARCH="AARCH64" && \
      export PLATFORM="ArmVirtPkg/ArmVirtQemu.dsc" \
    ;; \
    esac && \
    export PYTHON_COMMAND=python3 && \
    export WORKSPACE=/opt/edk2 && \
    export PACKAGES_PATH=/opt/edk2 && \
    export EDK_TOOLS_PATH=/opt/edk2/BaseTools/ && \
    export PATH=/opt/edk2/BaseTools/BinWrappers/PosixLike/:$PATH && \
    unset MAKEFLAGS && \
    bash -c ". edksetup.sh" && \
    make -C BaseTools && \
    build -b RELEASE \
        -a ${TARGET_ARCH} \
        -t GCC5 \
        -p ${PLATFORM} \
        -n 2 \
        -D SECURE_BOOT_ENABLE=TRUE \
        -D TPM2_ENABLE=TRUE \
        -D QEMU_PV_VARS=TRUE

# Copy whichever QEMU file we actually built into /opt
# For the aarch64 firmware, this is where we take the opportunity to pad
# the file to 64MB exactly, which is a requirement for aarch64 firmware
RUN arch="$(uname -m)" && \
    case "$arch" in \
    x86_64 | amd64) \
      cp -fv /opt/edk2/Build/OvmfX64/RELEASE_GCC5/FV/OVMF_CODE.fd /opt/OVMF_CODE.fd \
    ;; \
    aarch64 | arm64) \
      dd if=/opt/edk2/Build/ArmVirtQemu-AArch64/RELEASE_GCC5/FV/QEMU_EFI.fd of=/opt/OVMF_CODE.fd conv=notrunc && \
      truncate -s 64m /opt/OVMF_CODE.fd \
    ;; \
    esac

# Install virt-fw-vars to create some JSON vars stores
RUN dnf install -y python3-virt-firmware edk2-ovmf
# Create a blank JSON VARS store so we have something to
# work with if we don't want Secure Boot validation active
RUN virt-fw-vars \
  --output-json /opt/OVMF_VARS_INSECURE.json
# Create one based on the populated qcow2 VARS store that
# Fedora ship with their native OVMF build
#
# This is lazy and we could do this without relying on the
# Fedora package, but it involves messing around with Microsoft's
# certs ourselves
RUN virt-fw-vars \
  --input /usr/share/edk2/ovmf/OVMF_VARS_4M.secboot.qcow2 \
  --output-json /opt/OVMF_VARS_MS.json
# Build the VARS store that uses our custom Secure Boot keys
COPY keys/ /opt/keys
RUN virt-fw-vars \
  --output-json /opt/OVMF_VARS_CUSTOM.json \
  --set-pk-cert $(uuidgen) /opt/keys/pk-cert.pem \
  --add-db-cert $(uuidgen) /opt/keys/db-cert.pem \
  --microsoft-db none \
  --microsoft-kek none \
  --secure-boot

# Final container that just contains our firmware and nothing more
FROM docker.io/library/alpine:3.22
COPY --from=builder /opt/OVMF_CODE.fd /opt/OVMF_CODE.fd
COPY --from=builder /opt/OVMF_VARS_INSECURE.json /opt/OVMF_VARS_INSECURE.json
COPY --from=builder /opt/OVMF_VARS_MS.json /opt/OVMF_VARS_MS.json
COPY --from=builder /opt/OVMF_VARS_CUSTOM.json /opt/OVMF_VARS_CUSTOM.json
WORKDIR /opt
