{
  description = "NekOS Firmware";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.11";
  };

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          nekos-firmware =
            pkgs.stdenv.mkDerivation rec {
              pname = "nekos-firmware";
              version = "edk2-stable202511";

              # Moved here out of build.sh where AWS had it, and converted to
              # use the epoch directly, rather than calling the `date` command
              SOURCE_DATE_EPOCH = "1541062800"; # 2018-11-01 09:00:00 UTC

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

                # Normalise timestamps for reproducibility
                find . -type f -exec touch --date=@$SOURCE_DATE_EPOCH {} +
              '';

              buildPhase = ''
                # Ensure the Nix Python is exported as a var for scripts that read it
                export PYTHON_COMMAND="python3"

                patchShebangs ./build.sh
                patchShebangs BaseTools/BinWrappers/PosixLike/

                ./build.sh
              '';

              installPhase = ''
                mkdir -p $out
                cp -fv firmware.fd $out/firmware.fd
              '';

              dontPatchELF = true;

              meta = {
                description = "NekOS Firmware";
                homepage = "https://github.com/alexhaydock/NekOS/tree/main/firmware";
                platforms = lib.platforms.linux;
              };
            };

          default = self.packages.${system}.nekos-firmware;
        }
      );
    };
}
