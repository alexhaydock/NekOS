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

  buildInputs = with pkgs; [
    util-linux.dev
  ];

  # Do not allow the use of host binaries, for reproducibility's sake
  strictDeps = true;

  # Disable parallelism to improve reproducibility
  enableParallelBuilding = false;

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

  # Import custom firmware logo from current dir
  customLogo = ./logo.bmp;

  # From Nix upstream:
  #   https://github.com/NixOS/nixpkgs/blob/nixos-25.11/pkgs/applications/virtualization/OVMF/default.nix#L140-L145
  # Resolves OpenSSL build error:
  #   https://github.com/tianocore/edk2/issues/11186#issuecomment-2967614183
  hardeningDisable = [
    "format"
    "stackprotector"
    "pic"
    "fortify"
  ];

  patchPhase = ''
    # We need a custom patch phase because the default one uses 
    # the `patch` utility, which doesn't support binary Git diffs.

    for patchFile in $patches; do
      echo "Patch $patchFile"
      GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@localhost git apply "$patchFile"
    done

    # Copy in custom logo
    cp -fv ${customLogo} MdeModulePkg/Logo/Logo.bmp
  '';

  buildPhase = ''
    # Ensure the Nix Python is exported as a var for scripts that read it
    export PYTHON_COMMAND="python3"

    patchShebangs ./build.sh
    patchShebangs BaseTools/BinWrappers/PosixLike/

    ./build.sh
  '';

  installPhase = ''
    mkdir $out
    cp firmware.fd $out/firmware.fd
  '';

  meta = {
    description = "UEFI edk2 for NekOS";
    homepage = "https://github.com/alexhaydock/NekOS";
    license = "bsd";
  };
}
