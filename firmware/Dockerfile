FROM docker.io/nixos/nix:latest as builder

COPY . /opt/firmware

# Generate a new patch file from our build script if we've changed it
WORKDIR /opt/firmware/buildscript
RUN chmod +x build.sh && \
    git diff --no-index /dev/null build.sh | tee /opt/firmware/patches/0001-add-build-script.patch

WORKDIR /opt/firmware
RUN nix-build --pure && \
    cp -fv /opt/firmware/result/firmware.fd /opt/firmware.fd

# Final container that just contains our firmware and nothing more
FROM docker.io/library/alpine:3.23 as final
COPY --from=builder /opt/firmware.fd /opt/firmware.fd
