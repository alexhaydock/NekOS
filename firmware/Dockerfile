FROM docker.io/nixos/nix:latest as builder

# Re-enable Nix sandbox (requires running with --privileged)
# Without this, we won't get properly reproducible builds
#
# Normally I'd use awk/sed for this but we don't have them
# available in the Nix container, so we need to replace the
# whole file based on the one that's in the container
# by default
RUN bash -c 'echo -e "build-users-group = nixbld\nsandbox = true\ntrusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="' | tee /etc/nix/nix.conf

COPY . /opt/firmware

# Generate a new patch file from our build script if we've changed it
WORKDIR /opt/firmware/buildscript
RUN chmod +x /opt/firmware/build.sh && \
    git diff --no-index /dev/null build.sh | tee /opt/firmware/patches/0001-add-build-script.patch

# Ensure entrypoint is executable
RUN chmod +x /opt/firmware/entrypoint.sh

WORKDIR /opt/firmware
ENTRYPOINT ["/opt/firmware/entrypoint.sh"]
