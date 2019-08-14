#!/bin/bash

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
if test -f ! "${BUILD}"/enter.sh
then
    echo "$0: ${BUILD} exists, refusing to remove it.  To modify an existing build, simple 'source ${BUILD}/enter.sh'" >&2
    exit 1
fi

(
    source "${BUILD}"/enter.sh

    case "${MACHINE}"
    in
    qemu*) exec runqumu nographic slirp ;;
    *) echo "$0: unknown machine type '${MACHINE}'" >&2; exit 1;;
    esac
)
