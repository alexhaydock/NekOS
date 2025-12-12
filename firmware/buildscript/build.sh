#!/bin/bash
#shellcheck disable=all
# Copyright 2018-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
set -e -o pipefail

SOURCE="${BASH_SOURCE[0]}"
# resolve ${SOURCE} until the file is no longer a symlink
SOURCE="$(readlink -e ${SOURCE})"
DIR="$( cd -P "$( dirname ${SOURCE} )" && pwd )"
PACKAGES_PATH=${PACKAGES_PATH:-$DIR}

cd ${DIR}

TPUT="$([ -z "${TERM}" -o "${TERM}" = dumb ] && echo true || echo tput)"

${TPUT} setaf 2
echo "     BUILD  uefi"
${TPUT} sgr0

unset MAKEFLAGS
unset MAKELEVEL

# You can never be too safe. Just set these vars to '' to make sure no unwanted side effects occur
export CONF_PATH=''
export EDK_TOOLS_PATH=''
export WORKSPACE=''

# Set SOURCE_DATE_EPOCH for reproducible builds (can be overriden)
export SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(date --date='Nov 1 2018 09:00:00' +"%s")}

if [ -n "$UEFI_DEBUG" ]; then
	BUILD_TYPE="DEBUG"
else
	BUILD_TYPE="RELEASE"
fi

TOOLCHAIN="GCC5"

#
# build uefi in it's special build environment. This should be done last
# since it modifies the build environment
#
build_uefi()
{
	# Normalise mtimes for reproducibility
	find . -type f -exec touch --date=@$SOURCE_DATE_EPOCH {} +

	echo "      MAKE  BaseTools"
	make -C BaseTools
	source edksetup.sh

    determinism="-D SORT_COMPONENTS=TRUE -D BUILD_MULTIPLE_THREAD=FALSE"
	features="-D SECURE_BOOT_ENABLE=TRUE -D TPM2_ENABLE=TRUE -D QEMU_PV_VARS=TRUE"
	[ -n "$UEFI_DEBUG" ] && features="${features} -DDEBUG_ON_SERIAL_PORT"

	arch="$(uname -m)"
	case "$arch" in
		"x86_64" | "amd64")
			echo "     BUILD  OvmfPkg"
			build -a X64 -t $TOOLCHAIN -b $BUILD_TYPE --hash -p OvmfPkg/OvmfPkgX64.dsc ${features} ${determinism}
			cp Build/OvmfX64/${BUILD_TYPE}_${TOOLCHAIN}/FV/OVMF.fd firmware.fd
		;;
		"aarch64" | "arm64")
			echo "     BUILD  ArmVirtQemu"
			build -a AARCH64 -t $TOOLCHAIN -b $BUILD_TYPE --hash -p ArmVirtPkg/ArmVirtQemu.dsc ${features} ${determinism}
			cp Build/ArmVirtQemu-AArch64/${BUILD_TYPE}_${TOOLCHAIN}/FV/QEMU_EFI.fd firmware.fd

			# QEMU expects 64MiB CODE and VARS files on ARM/AARCH64 architectures
			# https://github.com/NixOS/nixpkgs/blob/09eb77e94fa25202af8f3e81ddc7353d9970ac1b/pkgs/applications/virtualization/OVMF/default.nix#L198
			truncate -s 64m firmware.fd
		;;
	esac
}

build_uefi
