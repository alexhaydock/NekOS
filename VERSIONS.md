# NekOS Software Versions

This page details the upstream software projects used to produce NekOS, along with details about the pinned versions and sources for rev-ing the versions from upstream.

### Version Pinning Matrix

| Component | Software | Pinning Method | Update Info |
|---|---|---|---|
| Firmware | Nix Container | _None_ | Uses `docker.io/nixos/nix:latest`. Build env pinning is left to `flake.lock`. |
| Firmware | Nix Build Environment | `flake.lock` | Manually update pinned versions periodically (see below). |
| Firmware | EDK2 | `pkgs.fetchFromGitHub` with pinned version string and SHA256 | Major releases every ~6 mo. [See GitHub](https://github.com/tianocore/edk2/releases).
| Kernel | Nix Container | _None_ | Uses `docker.io/nixos/nix:latest`. Build env pinning is left to `flake.lock`. |
| Kernel | Nix Build Environment | `flake.lock` | Manually update pinned versions periodically (see below). |
| Kernel | Linux Kernel | `pkgs.fetchurl` with pinned version string in `version` variable and pinned SHA256. | Update to latest stable periodically [from kernel.org](https://kernel.org/). |
| Kernel | Alpine Kernel Config | `pkgs.fetchurl` with pinned SHA256 | Update to latest `virt.*.config` file [from upstream](https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/linux-lts) when kernel version is rev'd. |

### Updating Nix `flake.lock` pinned package versions
The `flake.lock` pins the Nix Flake environment exactly. I version these in Git so the build environment is reproducible.

We can update this on a non-NixOS system as follows:

```sh
podman run --rm -it -v "${PWD}:/opt:Z" -w /opt -e NIX_CONFIG="experimental-features = nix-command flakes" docker.io/nixos/nix:latest
```

Then, in each directory with a Flake, we can run this **to generate a new lockfile**:

```sh
nix flake lock
```

or to **update an existing one**:
```sh
nix flake update
```

### Formatting `.nix` files
As a bonus to the above, we can install `nixpkgs-fmt` in a Nix container for easy Nix file reformatting (as it's not neatly packaged for other distros):

```sh
podman run --rm -it -v "${PWD}:/opt:Z" -w /opt -e NIX_CONFIG="experimental-features = nix-command flakes" docker.io/nixos/nix:latest
```

```sh
nix profile add nixpkgs#nixpkgs-fmt
nixpkgs-fmt flake.nix
```
