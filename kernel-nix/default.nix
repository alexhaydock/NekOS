{ pkgs ? import <nixpkgs> {} }:

let
  version = "6.18.1";

  src = pkgs.fetchurl {
    url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${version}.tar.xz";
    sha256 = "sha256-0KeL8/DRKqoQrzta3K7VvHZ7W3hwXl74hdXpMLcuJdU=";
  };

  x86Config = pkgs.fetchurl {
    url = "https://gitlab.alpinelinux.org/alpine/aports/-/raw/fbcf0dfbf88d6089620716343684b96d4d034431/main/linux-lts/virt.x86_64.config";
    sha256 = "sha256-zTbB0APDgSSdbbq1UpyrDx2XNrpIyRhW/6n5czc+VDg=";
  };
in

pkgs.stdenv.mkDerivation {
  pname = "nekos-kernel";
  inherit version src x86Config;

  nativeBuildInputs = with pkgs; [
    bc
    bison
    flex
    perl
    openssl
    elfutils
  ];

  # Reproducibility
  SOURCE_DATE_EPOCH = "0";
  KBUILD_BUILD_TIMESTAMP = "1970-01-01 00:00:00 UTC";
  KBUILD_BUILD_USER = "builder";
  KBUILD_BUILD_HOST = "nekos";
  KBUILD_BUILD_VERSION = "1";
  LANG = "C";
  LC_ALL = "C";
  TZ = "UTC";
  NIX_CFLAGS_COMPILE = "-O2 -fno-plt -fno-ident";
  NIX_LDFLAGS = "";

  configurePhase = ''
    runHook preConfigure

    # Patch shebangs in scripts so they run under Nix
    patchShebangs scripts/config

    # Import and configure Alpine's linux-virt config
    cp ${x86Config} .config
    make olddefconfig

    # Disable modules as a big source of non-determinism
    scripts/config --disable MODULES

    # Standard other reproducibility options
    scripts/config --disable DEBUG_INFO
    scripts/config --disable IKCONFIG
    scripts/config --disable IKHEADERS
    scripts/config --disable STACK_VALIDATION
    scripts/config --disable GCC_PLUGINS
    scripts/config --disable SYSTEM_TRUSTED_KEYS
    scripts/config --disable SYSTEM_REVOCATION_KEYS

    # Enable/configure the things we need for NekOS
    scripts/config --enable CONFIG_DRM_BOCHS
    scripts/config --enable CONFIG_DRM_FBDEV_EMULATION
    scripts/config --enable CONFIG_DRM_VIRTIO_GPU 
    scripts/config --enable CONFIG_LOGO
    scripts/config --set-str LOCALVERSION "-nekos"

    # Run olddefconfig again, and do it twice, just
    # to be extra sure of consistency
    make olddefconfig
    make olddefconfig

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    make \
      -j$NIX_BUILD_CORES \
      V=0 \
      bzImage

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp arch/x86/boot/bzImage $out/vmlinuz
    runHook postInstall
  '';

  dontStrip = true;
  enableParallelBuilding = true;
}
