#!/bin/bash

set -e
set -o pipefail

# Handle the command-line arguments, with some defaults.  The arguments without
# defaults are checked below the processing loop.
BUILD="build"
TOP="$(readlink -f .)"
unset MACHINE
unset IMAGE

if test ! -e "${TOP}"/openembedded-core/bitbake
then
    ln -s ../bitbake "${TOP}"/openembedded-core/bitbake
fi

while [[ "$1" != "" ]]
do
    case "$1" in
    --machine)    MACHINE="$2";                             shift 2;;
    --machine=*)  MACHINE="$(echo "$1" | cut -d= -f2-)";    shift 1;;
    --image)      IMAGE="$2";                               shift 2;;
    --image=*)    IMAGE="$(echo "$1" | cut -d= -f2-)";      shift 1;;
    *) echo "$0: unknown argument $1" >&2; exit 1;;
    esac
done

if [[ "${MACHINE}" == "" ]]
then
    echo "$0: --machine <machine name>: You must specify a target machine.  Availiable machines:" >&2
    ./tools/list-machines >&2
    exit 1
fi

if [[ "${IMAGE}" == "" ]]
then
    echo "$0: --image <image name>: You must specify an image to generate.  Availiable images:" >&2
    ./tools/list-images >&2
    exit 1
fi

BUILD="${BUILD}/${MACHINE}-${IMAGE}"

# Check to make sure the environment isn't too screwed up, as otherwise we'll
# get some ugly error messages.
#if test -d "${BUILD}"
#then
#    echo "$0: ${BUILD}/enter.sh doesn't exist, have you run ./build?"
#    exit 1
#fi

mkdir -p "${BUILD}"

(
    # Use OpenEmbedded's tools to initialize the build environment, which both sets
    # a handful of environment variables and changes into the build directory.
    # That's why we're in a subshell.
    source "${TOP}/openembedded-core/oe-init-build-env" "${BUILD}" > /dev/null
    
    # Configures the bitbake layers.  We expect this to have been run from a clean
    # directory, se we just add everything in here.
    bitbake-layers add-layer "${TOP}"/meta-openembedded/meta-oe
    bitbake-layers add-layer "${TOP}"/meta-openembedded/meta-python
    bitbake-layers add-layer "${TOP}"/meta-openembedded/meta-multimedia
    bitbake-layers add-layer "${TOP}"/meta-openembedded/meta-networking
    bitbake-layers add-layer "${TOP}"/meta-openembedded/meta-gnome
    bitbake-layers add-layer "${TOP}"/meta-openembedded/meta-xfce
    bitbake-layers add-layer "${TOP}"/meta-riscv
    bitbake-layers add-layer "${TOP}"/meta-sifive
    
    # Configures bitbake, which for us is just setting the target.
    cat >conf/auto.conf <<EOF
MACHINE ?= "${MACHINE}"
EXTRA_IMAGE_FEATURES_append = " package-management"
PACKAGECONFIG_append_pn-qemu-native = " sdl"
PACKAGECONFIG_append_pn-nativesdk-qemu = " sdl"
USER_CLASSES ?= "buildstats buildhistory buildstats-summary image-mklibs image-prelink"
require conf/distro/include/no-static-libs.inc
require conf/distro/include/yocto-uninative.inc
require conf/distro/include/security_flags.inc
INHERIT += "uninative"
DISTRO_FEATURES_append = " largefile opengl ptest multiarch wayland pam  systemd "
DISTRO_FEATURES_BACKFILL_CONSIDERED += "sysvinit"
VIRTUAL-RUNTIME_init_manager = "systemd"
HOSTTOOLS_NONFATAL_append = " ssh"
# We use NetworkManager instead
PACKAGECONFIG_remove_pn-systemd = "networkd"
# Disable security flags for bootloaders
# Security flags incl. smatch protector which is not supported in these packages
SECURITY_CFLAGS_pn-freedom-u540-c000-bootloader = ""
SECURITY_LDFLAGS_pn-freedom-u540-c000-bootloader = ""
SECURITY_CFLAGS_pn-opensbi = ""
SECURITY_LDFLAGS_pn-opensbi = ""
# Add r600 drivers for AMD GPU
PACKAGECONFIG_append_pn-mesa = " r600"
EOF

    # Builds the requested image.
    ionice -c3 nice -n19 bitbake "${IMAGE}"
)

# Creates a script that allows users to enter the openembedded environment for
# further development.
cat > "${BUILD}"/enter.sh <<EOF
source "${TOP}/openembedded-core/oe-init-build-env" "$(readlink -f "${BUILD}")" > /dev/null
EOF

# Inform the user of how to run their image
echo "$0: Your image is ready, run './run.sh --machine ${MACHINE} --image ${IMAGE}'"
