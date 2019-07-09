# SiFive Freedom Unleashed SDK

This builds a complete RISC-V cross-compile toolchain for the SiFive Freedom Unleashed U500 SoC. It also builds a `bbl` image for booting the Freedom Unleashed development board.

## Tested Configurations

### Ubuntu 16.04 x86_64 host

- Status: Working
- Build dependencies: `build-essential git autotools texinfo bison flex libgmp-dev libmpfr-dev libmpc-dev gawk libz-dev libssl-dev`
- Additional build deps for QEMU: `libglib2.0-dev libpixman-1-dev`
- Additional build deps for Spike: `device-tree-compiler`

### Arch Linux x86_64 Host

 - Status: Not working (Broken Python development environment)

## Build Instructions

Checkout this repository. Then you will need to checkout all of the linked submodules using:

`git submodule update --recursive --init`

This will take some time and require around 7GB of disk space. Some modules may fail because certain dependencies don't have the best git hosting. The only solution is to wait and try again later (or ask someone for a copy of that source repository).

Once the submodules are initialized, run `make` and the complete toolchain and bbl image will be built. The completed build tree will consume about 14G of disk space.

### Build BBL with a mountpoint for the root filesystem

Specify the mountpoint with:

`make <DEVICE=> [OFFSET=]`

For example if `DEVICE=mmcblk0` and `OFFSET=32`, the initramfs will try to find the root filesystem on `/dev/mmcblk0` at an offset of `32M` and mount it at `/mnt`. This process is run by the last script in /etc/init.d.

`OFFSET` has a default value of `32`.

### Build BBL with an alternate /init script

The default /init script of initramfs is the BusyBox implementation. The user can use their own version of /init using:

`make <INIT=>`

`INIT` should be a path to the /init script. It can be either a relative or absolute path. An example script is `./conf/init`.

### Load the bbl and root filesystem onto the SD card

`sudo make load-sd-card <DEVICE=> [ROOT=] [BOOTLOADER=] [OFFSET=]`

* `DEVICE` is the block device under /dev that will be written to. For example, `DEVICE=sda` means the target device is `/dev/sda`.
* `ROOT` is the path to the disk image containing the root filesystem. If unspecified, the program will not write a root filesystem to the device.
    * If `ROOT=qemu-elf`, the build system will automatically convert the `qemu-elf` submodule to a disk image and write that to the sd card.
* `BOOTLOADER` is the BBL that will be written to target device. If unspecified, default `BOOTLOADER` is `./work/bbl.bin`, which is the default output path of bbl.bin of `make`.
* `OFFSET` is the number of MB's for the offset of root filesystem. 1MB is defined as 1024*1024 bytes. In unspecified, `OFFSET=32` by default.

### Clean the Buildroot initramfs

The user can clean the compiled buildroot initramfs sysroot without cleaning the compiled kernel. This can be done with:

`make clean-initramfs`

## Upgrading the BBL for booting the Freedom Unleashed dev board

Once the build of the SDK is complete, there will be a new bbl image under `work/bbl.bin`. This can be copied to the first partition of the MicroSD card using the `dd` tool.

## Booting Linux on a simulator

You can boot linux on qemu by running `make qemu`.

You can boot linux on spike by running `make sim`.  This requires a patch to
enable the old serial driver, because the new one which works best on the
Freedom Unleashed hardware unfortunately does not work on spike.

```
diff --git a/conf/linux_defconfig b/conf/linux_defconfig
index cd87340..87b480f 100644
--- a/conf/linux_defconfig
+++ b/conf/linux_defconfig
@@ -53,7 +53,7 @@ CONFIG_SERIAL_8250_CONSOLE=y
 CONFIG_SERIAL_OF_PLATFORM=y
 CONFIG_SERIAL_SIFIVE=y
 CONFIG_SERIAL_SIFIVE_CONSOLE=y
-# CONFIG_HVC_RISCV_SBI is not set
+CONFIG_HVC_RISCV_SBI=y
 CONFIG_VIRTIO_CONSOLE=y
 # CONFIG_HW_RANDOM is not set
 CONFIG_I2C=y
```
