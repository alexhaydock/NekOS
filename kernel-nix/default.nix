{
  pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.11.tar.gz";
    sha256 = "sha256:1zn1lsafn62sz6azx6j735fh4vwwghj8cc9x91g5sx2nrg23ap9k";
  }) {}
}:

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
    xz
  ];

  # Reproducibility
  KBUILD_BUILD_TIMESTAMP="1970-01-01 00:00:00 UTC";
  KBUILD_BUILD_USER="builder";
  KBUILD_BUILD_HOST="nekos";
  SOURCE_DATE_EPOCH=0;
  KBUILD_ABS_SRCTREE=0;
  GZIP="-n";
  XZ_DEFAULTS="--threads=1 --no-adjust";
  LANG="C";
  LC_ALL="C";
  TZ="UTC";
  KCFLAGS = "-O2 -g -ffile-prefix-map=${src}=. -fdebug-prefix-map=${src}=.";

  configurePhase = ''
    runHook preConfigure

    # Patch shebangs in config scripts so they run under Nix
    patchShebangs scripts/config

    # Import and configure Alpine's linux-virt config
    cp ${x86Config} .config
    make olddefconfig

    # Disable kernel modules for reproducibility's sake
    scripts/config --disable MODULES
    make olddefconfig

    # Disable a bunch of other flags that might impact reproducibility
    scripts/config --disable DEBUG_INFO
    scripts/config --disable GCC_PLUGINS
    scripts/config --disable IKCONFIG
    scripts/config --disable IKHEADERS
    scripts/config --disable STACK_VALIDATION
    scripts/config --disable SYSTEM_REVOCATION_KEYS
    scripts/config --disable SYSTEM_TRUSTED_KEYS
    make olddefconfig

    # Enable/configure some tweaks for NekOS
    scripts/config --enable CONFIG_LOGO
    scripts/config --set-str CONFIG_DEFAULT_HOSTNAME "nekos"
    scripts/config --set-str LOCALVERSION "-nekos"
    make olddefconfig

    # Run make olddefconfig again just to make sure
    # See: https://github.com/NixOS/nixpkgs/blob/09eb77e94fa25202af8f3e81ddc7353d9970ac1b/pkgs/os-specific/linux/kernel/generate-config.pl#L128-L132
    make olddefconfig

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    make \
      -j1 \
      V=0 \
      KCFLAGS="$KCFLAGS" \
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
