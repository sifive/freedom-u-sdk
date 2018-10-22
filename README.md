# SiFive Freedom Uleashed SDK

This builds a complete RISC-V cross-compile toolchain for the SiFive Freedom Unleashed U500 SoC. It also builds a `bbl` image for booting the Freedom Unleash development board.

## Tested Configurations

### Ubuntu 16.04 x86_64 host

- Status: Working
- Build dependencies: `build-essential git autotools texinfo bison flex libgmp-dev libmpfr-dev libmpc-dev`

### Arch Linux x86_64 Host

 - Status: Not working (Broken Python development environment)

## Build Instructions

Checkout this repository. Then you will need to checkout all of the linked submodules using:

`git submodule update --recursive --init`

This will take some time and require around 7GB of disk space. Some modules may fail because certain dependencies don't have the best git hosting. The only solution is to wait and try again later (or ask someone for a copy of that source repository).

Once the submodules are initialized, run `make` and the complete toolchain and bbl image will be built. The completed build tree will consume about 14G of disk space.

## Upgrading the BBL for booting the Freedom Unleashed dev board

Once the build of the SDK is complete, there will be a new bbl image under `work/bbl.bin`. This can be copied to the first partition of the MicroSD card using the `dd` tool.

