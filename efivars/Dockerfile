FROM registry.fedoraproject.org/fedora:43 as builder

# Install virt-fw-vars to create some JSON vars stores
RUN dnf install -y \
        edk2-ovmf \
        python3-virt-firmware \
        uuidgen && \
    dnf clean all

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
  --set-pk-cert "$(uuidgen)" /opt/keys/pk-cert.pem \
  --add-db-cert "$(uuidgen)" /opt/keys/db-cert.pem \
  --microsoft-db none \
  --microsoft-kek none \
  --secure-boot

# Final container that just contains our firmware and nothing more
FROM docker.io/library/alpine:3.23 as final
COPY --from=builder /opt/OVMF_VARS_INSECURE.json /opt/OVMF_VARS_INSECURE.json
COPY --from=builder /opt/OVMF_VARS_MS.json /opt/OVMF_VARS_MS.json
COPY --from=builder /opt/OVMF_VARS_CUSTOM.json /opt/OVMF_VARS_CUSTOM.json
WORKDIR /opt
