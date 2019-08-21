# freedom-u-sdk: SiFive's SDK for U Core IP

This repository makes it easy to get started developing software for the
Freedom U Linux-capable RISC-V Platforms.  This SDK is intended to work
on Linux-based hosts, and targets SiFive's HiFive Unleashed development
board.

## Quick Start for the HiFive Unleashed

    git clone https://github.com/sifive/freedom-u-sdk.git --recursive
    cd freedom-u-sdk
    ./build.sh --machine=sifive-hifive-unleashed --image=sifive-coreip-demo-experimental
    ./run.sh --machine=sifive-hifive-unleashed --image=sifive-coreip-demo-experimental

This provides an image that can be flashed to a micro SD card and run on
the HiFive Unleashed.  This image contains an FSBL, BBL, Linux, and
initramfs-based userspace -- in other words, everything that can be
written on the device.  You must set the MSEL to 1011 in order to boot
this style of image.

## Introduction


