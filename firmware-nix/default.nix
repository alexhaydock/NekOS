# Based on:
# https://github.com/aws/uefi

{
  pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/22.11.tar.gz";
    sha256 = "sha256:11w3wn2yjhaa5pv20gbfbirvjq6i3m7pqrq2msf0g7cv44vijwgw";
  }) {}
}:
pkgs.stdenv.mkDerivation rec {
  pname = "nekos-firmware";
  version = "edk2-stable202211";

  nativeBuildInputs = with pkgs; [
    acpica-tools
    git
    libuuid
    nasm
    ncurses
    python3
  ];

  # To rev this version we can set a dummy sha256 string of:
  #   "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  # And then run a build, to have Nix tell us the actual hash.
  src = pkgs.fetchFromGitHub {
    owner = "tianocore";
    repo = "edk2";
    rev = "edk2-stable202211";
    fetchSubmodules = true;
    sha256 = "sha256-0jE73xPyenAcgJ1mS35oTc5cYw7jJvVYxhPdhTWpKA0=";
  };

  patches = [
    ./patches/0001-add-build-script.patch
    ./patches/9001-Remove-Wno-format-compiling-flag-for-Openssl-files.patch
  ];

  patchPhase = ''
    # We need a custom patch phase because the default one uses the `patch` utility, which doesn't support binary Git diffs.

    for patchFile in $patches; do
      echo "Patch $patchFile"
      GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@localhost git apply "$patchFile"
    done
  '';

  buildPhase = ''
    patchShebangs ./build.sh
    patchShebangs BaseTools/BinWrappers/PosixLike/

    ./build.sh x86
  '';

  installPhase = ''
    mkdir $out
    cp ovmf_img.fd $out/ovmf_img.fd
  '';

  meta = {
    description = "UEFI edk2 for NekOS";
    homepage = "https://github.com/alexhaydock/NekOS";
    license = "bsd";
  };
}
