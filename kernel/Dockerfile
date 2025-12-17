FROM docker.io/nixos/nix:latest as builder

# Enable the Nix CLI so we can actually run `nix build`
ENV NIX_CONFIG="experimental-features = nix-command flakes"

# Re-enable Nix sandbox (requires running with --privileged)
# Without this, we won't get properly reproducible builds
#
# Normally I'd use awk/sed for this but we don't have them
# available in the Nix container, so we need to replace the
# whole file based on the one that's in the container
# by default
RUN bash -c 'echo -e "build-users-group = nixbld\nsandbox = true\ntrusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="' | tee /etc/nix/nix.conf && \
    cat /etc/nix/nix.conf

COPY . /opt/nixbuild

# Ensure entrypoint is executable
RUN chmod +x /opt/nixbuild/entrypoint.sh

WORKDIR /opt/nixbuild
ENTRYPOINT ["/opt/nixbuild/entrypoint.sh"]
