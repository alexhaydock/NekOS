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
  version = "edk2-stable202511";

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
    rev = "edk2-stable202511";
    fetchSubmodules = true;
    sha256 = "sha256-R/rgz8dWcDYVoiM67K2UGuq0xXbjjJYBPtJ1FmfGIaU=";
  };

  patches = [
    ./patches/0001-add-build-script.patch
  ];

  patchPhase = ''
    # We need a custom patch phase because the default one uses the `patch` utility, which doesn't support binary Git diffs.

    for patchFile in $patches; do
      echo "Patch $patchFile"
      GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@localhost git apply "$patchFile"
    done
  '';

  buildPhase = ''
    # Ensure the Nix Python is exported as a var for scripts that read it
    export PYTHON_COMMAND="python3"

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
