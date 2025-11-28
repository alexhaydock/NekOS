FROM docker.io/library/alpine:edge
RUN apk --no-cache add ukify openssl py3-cryptography rsync

# Create key output dir
RUN mkdir -p /opt/keys

# Generate Secure Boot DB & PCR keys
RUN ukify genkey \
  --secureboot-private-key=/opt/keys/db-priv.pem \
  --secureboot-certificate=/opt/keys/db-cert.pem \
  --pcr-private-key=/opt/keys/tpm2-pcr-initrd-priv.pem \
  --pcr-public-key=/opt/keys/tpm2-pcr-initrd-cert.pem

# Generate Secure Boot PK key to provide the overall
# root of trust for our firmware. We don't really use
# this directly since we're not singing updates, but we
# need it to switch our firmware out of Setup Mode
RUN openssl req -newkey rsa:4096 -nodes -keyout /opt/keys/pk-priv.key -new -x509 -sha256 -days 3650 -subj "/CN=NekOS Secure Boot PK/" -out /opt/keys/pk-cert.pem
