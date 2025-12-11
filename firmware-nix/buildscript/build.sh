#!/bin/bash
#shellcheck disable=all
# Copyright 2018-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
set -e -o pipefail

ARCH_TARGET="$1"

# Check parameters
SUPPORTED_ARCH="arm64 x86"
if [[ ! " $SUPPORTED_ARCH " =~ .*\ $ARCH_TARGET\ .* ]]; then
	echo "Usage: $0 <arch>"
	echo "Supported architectures: ${SUPPORTED_ARCH[@]}"
	exit 2
fi

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
	echo "      MAKE  BaseTools"
	make -C BaseTools
	source edksetup.sh

	if [ "$ARCH_TARGET" = "x86" ]; then
	    # Build OVMF for booting x86_64 Nitro Guests
	    echo "     BUILD  OvmfPkg"

	    defines="${defines} -DSECURE_BOOT_ENABLE=TRUE -DTPM2_ENABLE=TRUE"
	    [ -n "$UEFI_DEBUG" ] && defines="${defines} -DDEBUG_ON_SERIAL_PORT"

	    build -a X64 -t $TOOLCHAIN -b $BUILD_TYPE --hash -p OvmfPkg/OvmfPkgX64.dsc ${defines}
	    cp Build/OvmfX64/${BUILD_TYPE}_${TOOLCHAIN}/FV/OVMF.fd ovmf_img.fd

	elif [ "$ARCH_TARGET" = "arm64" ]; then
	    # Build ArmvirtQemuKernel, passed to Nitro Guests
	    echo "     BUILD  ArmVirtQemuKernel"
	    build -a AARCH64 -t $TOOLCHAIN -b $BUILD_TYPE --hash -p ArmVirtPkg/ArmVirtQemuKernel.dsc
	    cp Build/ArmVirtQemuKernel-AARCH64/${BUILD_TYPE}_${TOOLCHAIN}/FV/QEMU_EFI.fd uefi_img.fd

	else
	    echo "ERROR: Unknown UEFI build target ${ARCH_TARGET}"
	    exit 1
	fi
}

build_uefi
