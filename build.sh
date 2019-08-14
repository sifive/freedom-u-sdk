#!/bin/bash

set -e
set -o pipefail

# Handle the command-line arguments, with some defaults.  The arguments without
# defaults are checked below the processing loop.
BUILD="build"
TOP="$(readlink -f .)"
unset MACHINE
unset IMAGE

while [[ "$1" != "" ]]
do
    case "$1" in
    --machine)    MACHINE="$2";  shift 2;;
    --image)      IMAGE="$2";    shift 2;;
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
if test -d "${BUILD}"
then
    echo "$0: ${BUILD}/enter.sh doesn't exist, have you run ./build?"
    exit 1
fi

if test ! -e "${TOP}"/meta-riscv/setup.sh
then
    echo "$0: ${TOP}/meta-riscv/setup.sh doesn't exist, did you forget to run 'git submodule update --init --recursive'?" >&2
    exit 1
fi

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
    bitbake-layers add-layer "${TOP}"/meta-riscv
    bitbake-layers add-layer "${TOP}"/meta-sifive
    
    # Configures bitbake, which for us is just setting the target.
    cat >conf/auto.conf <<EOF
MACHINE = "${MACHINE}"
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
