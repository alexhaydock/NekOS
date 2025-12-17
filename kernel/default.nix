# Import pinned Nixpkgs
{
  pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.11.tar.gz";
    sha256 = "sha256:1zn1lsafn62sz6azx6j735fh4vwwghj8cc9x91g5sx2nrg23ap9k";
  }) {} , system ? pkgs.stdenv.hostPlatform.system }:

# Define kernel version, download path and Alpine configs to use
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

  aarch64Config = pkgs.fetchurl {
    url = "https://gitlab.alpinelinux.org/alpine/aports/-/raw/fbcf0dfbf88d6089620716343684b96d4d034431/main/linux-lts/virt.aarch64.config";
    sha256 = "sha256-LvDuCwlba3sv2f+FcXdgmWK+xx0tkHIY2rWj7DgzUUw=";
  };

  kernelConfig = if system == "x86_64-linux" then x86Config else aarch64Config;
in

# Define some platform-specific variables
let
  inherit (pkgs.stdenv.hostPlatform) isx86_64 isAarch64;

  kernelConfig =
    if isx86_64 then x86Config
    else if isAarch64 then aarch64Config
    else throw "Unsupported platform: ${pkgs.stdenv.hostPlatform.system}";

  kernelMakeTarget =
    if isx86_64 then "bzImage"
    else if isAarch64 then "Image"
    else throw "Unsupported platform: ${pkgs.stdenv.hostPlatform.system}";

  kernelImagePath =
    if isx86_64 then "arch/x86/boot/bzImage"
    else if isAarch64 then "arch/arm64/boot/Image"
    else throw "Unsupported platform: ${pkgs.stdenv.hostPlatform.system}";

  # If we're running aarch64, disable CRYPTO_AEGIS128_SIMD
  # to avoid build failures on the default ARM-based GitHub runners
  # See: https://github.com/NixOS/nixpkgs/blob/6812bcfd614abedbdb3f68d7b6554eda6ca3e014/pkgs/os-specific/linux/kernel/common-config.nix#L1458-L1459
  extraConfigCommands = pkgs.lib.optionalString isAarch64 ''
    scripts/config --disable CRYPTO_AEGIS128_SIMD
  '';
in

pkgs.stdenv.mkDerivation {
  pname = "nekos-kernel";
  inherit version src;

  # KBuild reproducibility
  # (SOURCE_DATE_EPOCH not needed as Nix handles this itself based on the newest
  # file found when the source tarball gets unpacked)
  KBUILD_ABS_SRCTREE = "0";
  KBUILD_BUILD_HOST = "nekos";
  KBUILD_BUILD_TIMESTAMP = "1970-01-01 00:00:00 UTC";
  KBUILD_BUILD_USER = "builder";
  KBUILD_BUILD_VERSION = "1";

  # Pin locale for reproducibility
  LANG = "C";
  LC_ALL = "C";
  TZ = "UTC";

  # Try and make any compression processes
  # more deterministic than they might be
  # by default
  GZIP = "-n";
  XZ_DEFAULTS = "--threads=1 --no-adjust";

  nativeBuildInputs = with pkgs; [
    bc
    bison
    flex
    perl
    openssl
    elfutils
    xz
  ];

  configurePhase = ''
    runHook preConfigure

    # Patch shebangs in config scripts so they run under Nix
    patchShebangs scripts/config

    # Import and configure Alpine's linux-virt config based on our arch
    cp -fv ${kernelConfig} .config
    make olddefconfig

    # Disable kernel modules for reproducibility's sake
    scripts/config --disable MODULES
    make olddefconfig

    # Disable a bunch of other flags that might impact reproducibility
    scripts/config --disable DEBUG_INFO
    scripts/config --disable GCC_PLUGINS
    scripts/config --disable IKCONFIG
    scripts/config --disable IKHEADERS
    scripts/config --disable LOCALVERSION_AUTO
    scripts/config --disable STACK_VALIDATION
    scripts/config --disable SYSTEM_REVOCATION_KEYS
    scripts/config --disable SYSTEM_TRUSTED_KEYS
    make olddefconfig

    # Enable/configure some tweaks for NekOS
    scripts/config --enable LOGO
    scripts/config --set-str DEFAULT_HOSTNAME "nekos"
    scripts/config --set-str LOCALVERSION "-nekos"
    make olddefconfig

    # Import any arch-specific commands we defined earlier
    ${extraConfigCommands}

    # Run make olddefconfig again just to make sure
    # See: https://github.com/NixOS/nixpkgs/blob/09eb77e94fa25202af8f3e81ddc7353d9970ac1b/pkgs/os-specific/linux/kernel/generate-config.pl#L128-L132
    make olddefconfig

    runHook postConfigure
  '';

  # Build kernel
  buildPhase = ''
    runHook preBuild

    make \
      -j$NIX_BUILD_CORES \
      V=0 \
      ${kernelMakeTarget}

    runHook postBuild
  '';

  # Copy built artefacts into output directory
  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -fv ${kernelImagePath} $out/kernel
    cp -fv ${kernelConfig} $out/kernelconfig-alpine
    cp -fv .config $out/kernelconfig-nekos

    runHook postInstall
  '';

  dontStrip = true;
  enableParallelBuilding = true;

  meta = {
    description = "NekOS Kernel";
    homepage = "https://github.com/alexhaydock/NekOS/tree/main/kernel";
  };
}
