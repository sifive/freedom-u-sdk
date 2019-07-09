# SiFive Freedom Unleashed SDK

This builds a complete RISC-V cross-compile toolchain for the SiFive Freedom
Unleashed U500 SoC. It also builds U-boot and a flattened image tree (FIT)
image with a BBL binary, linux kernel, device tree, and ramdisk for the HiFive
Unleashed development board.

## Tested Configurations

### Ubuntu 16.04 x86_64 host

- Status: Working
- Build dependencies: `build-essential git autotools texinfo bison flex
  libgmp-dev libmpfr-dev libmpc-dev gawk libz-dev libssl-dev`
- Additional build deps for QEMU: `libglib2.0-dev libpixman-1-dev`
- Additional build deps for Spike: `device-tree-compiler`
- tools require for 'format-boot-loader' target: mtools

### Debian Linux (sid) RiscV Host

- Status: Not supported (Riscv-gnu-toolchain does not build natively)
- Likely to work with native Debian gcc 

## Build Instructions

Checkout this repository. Then you will need to checkout all of the linked
submodules using:

`git submodule update --recursive --init`

This will take some time and require around 7GB of disk space. Some modules may
fail because certain dependencies don't have the best git hosting. The only
solution is to wait and try again later (or ask someone for a copy of that
source repository).

Once the submodules are initialized, run `make` and the complete toolchain
and images will be built. The completed build tree will consume about 14G of disk
space.

## Updates from previous freedom-u-sdk versions

The compiler toolchain vendor string has changed to 'riscv64-sifive-linux-gnu',
and the easiest (but slowest) way to update is remove the entire 'work/*' set
of directories and re-run make.

## Upgrading to U-boot for booting the Freedom Unleashed dev board

Once the build of the SDK is complete, there will be a new u-boot FIT image
under 'work/image-(GITID).fit', where GITID is the short git has of the commit
to freedom-u-sdk the image was build from. This can be copied to the first
partition of the MicroSD card, which should be formatted as an MSDOS partition
and contain a file called 'uEnv.txt' which contains the default U-boot environment.
This file can be edited to change boot behavior. See the inline comments in the file
for further information. (The file can be found in conf/uEnv.txt as well)

To boot U-boot, the currently supported method is to set the mode select
switches to boot from the SDcard, and have U-boot on an SDcard, which can be
formatted and set up with the command: 

`make DISK=/dev/sdX format-boot-loader`

where X is replaced with the device name of the SDcard. Alternatively, to
download a pre-built Debian demo image, use the 'format-demo-image' target with
the same syntax. You may need to use sudo if you do not have udev rules set.

TODO: document Udev rules to allow this to run without root or sudo

The hifive-unleashed-a00-YYYY-MM-DD.gpt image file can be written to the flash
with `dd` or another similiar tool, or flashed to the SPI flash with `flashcp`.
Running from flash is not (yet) well supported, please file issues and send
patches to fix problems.

The mode select switches should be set as follows:
```
      USB   LED    Mode Select                  Ethernet
 +===|___|==****==+-+-+-+-+-+-+=================|******|===+
 |                | | | | |X| |                 |      |   |
 |                | | | | | | |                 |      |   |
 |        HFXSEL->|X|X|X|X| |X|                 |______|   |
 |                +-+-+-+-+-+-+                            |
 |        RTCSEL-----/ 0 1 2 3 <--MSEL                     |
 |                                                         |
```

## Booting Linux on a simulator

You can boot linux on qemu by running `make qemu`.

You can boot linux on spike by running `make sim`.  This requires a patch to
enable the old serial driver, because the new one which works best on the
Freedom Unleashed hardware unfortunately does not work on spike.

The current build process also does not include an initrd with spike, so
even if you do boot the kernel it will not have a root filesystem. If you
would like to help, please see the qemu code for separate firmware and
kernel payload options (commit 16aad29) or add an option to the riscv-pk
build to allow a '--with-ramdisk' option, and send a patch or pull request.
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
