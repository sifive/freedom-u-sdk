# SiFive Freedom Unleashed SDK

The new experimental Freedom Unleashed (FU) SDK is based on OpenEmbedded (OE). It's a minimal [meta-sifive](https://github.com/sifive/meta-sifive) layer on top of [meta-riscv](https://github.com/riscv/meta-riscv) to provide additional modifications and new disk image targets. Using OE you will be able to:

- build predefined disk images for QEMU and [SiFive HiFive Unleashed](https://www.sifive.com/boards/hifive-unleashed) development board (incl. [HiFive Unleashed Expansion Board](https://www.crowdsupply.com/microsemi/hifive-unleashed-expansion-board) from Microsemi);
- build custom disk images with additional software packages from various third-party OE layers;
- quickly launch QEMU VM instance with your built disk image;
- build bootloader binaries (ZSBL, FSBL, OpenSBI, U-Boot);
- build Device Tree Binary (DTB);
- build Linux kernel images;
- easily modify disk partition layout.

> [Berkeley Boot Loader (BBL)](https://github.com/riscv/riscv-pk) is replaced by [OpenSBI](https://github.com/riscv/opensbi) and uSD (microSD) disk images now also incl. [FSBL](https://github.com/sifive/freedom-u540-c000-bootloader). ZSBL is also built, but it's not possible to use it as it resides in ROM.

For more information on particular release see `ReleaseNotes` directory in [freedom-u-sdk](https://github.com/sifive/freedom-u-sdk) repository on GitHub.

The old SDK based on Buildroot is archived in [`archive/buildroot`](https://github.com/sifive/freedom-u-sdk/tree/archive/buildroot) branch.

For advanced OE usage we advice to look into the following third-party manuals:

- [BitBake User Manual 2.7.1 by Yocto](https://www.yoctoproject.org/docs/2.7.1/bitbake-user-manual/bitbake-user-manual.html)

- [Yocto Project Reference Manual 2.7.1 by Yocto](https://www.yoctoproject.org/docs/2.7.1/ref-manual/ref-manual.html)

- [Yocto Project Complete Documentation \(MegaManual\) Set 2.7.1 by Yocto](https://www.yoctoproject.org/docs/2.7.1/mega-manual/mega-manual.html)

- [A practical guide to BitBake by Harald Achitz](https://a4z.bitbucket.io/docs/BitBake/guide.html)

## Quick Start

Install `repo` command from Google if not available on your host system. Please follow [the official instructions](https://source.android.com/setup/downloading#installing-repo) by Google.

Then install a number of packages for BitBake (OE build tool) to work properly on your host system. BitBake itself depends on Python 3. Once you have Python 3 installed BitBake should be able to tell you most of the missing packages.

> For Ubuntu 18.04 (or newer) install python3-distutils package.

Detailed instructions for various distributions can be found in "[Required Packages for the Build Host](https://www.yoctoproject.org/docs/2.7.1/ref-manual/ref-manual.html#required-packages-for-the-build-host)" section in Yocto Project Reference Manual.

### Creating Workspace

This needs to be done every time you want a clean setup based on the latest layers.

```bash
mkdir riscv-sifive && cd riscv-sifive
repo init -u git://github.com/sifive/meta-sifive -b v201908-branch -m tools/manifests/sifive.xml
repo sync
```

### Creating a Working Branch

If you want to make modifications to existing layers then creating working branches in all repositories is advisable.

```bash
repo start work --all
```

### Updating Existing Workspace

If you want to pull in the latest changes in all layers.

```bash
cd riscv-sifive
repo sync
repo rebase
```

### Setting up Build Environment

```bash
. ./meta-sifive/setup.sh
```

### Building Disk Images

There are two disk image targets added by meta-sifive layer:

- `demo-coreip-cli` - basic command line image (**recommended**);

- `demo-coreip-xfce4` - basic graphical disk image with [Xfce 4](https://www.xfce.org/) desktop environment (requires HiFive Unleashed Expansion Board with supported GPUs, for example, Radeon HD 6450 or Radeon HD 5450).

There are two machine targets currently tested:

- `qemuriscv64` - RISC-V 64-bit (RV64GC) for QEMU virt machine;

- `freedom-u540` - SiFive HiFive Unleashed development board with or without HiFive Unleashed Expansion Board from Microsemi.

> It's not possible to use disk images built for `freedom-u540` with QEMU 4.0 and instructions provided below.
> 
> Building disk images is CPU intensive, requires <10GB of sources downloaded over the Internet and <110GB of local storage.

Building disk image takes a single command which my take anything from 30 minutes to several hours depending on your hardware. Examples:

```bash
MACHINE=qemuriscv64 bitbake demo-coreip-cli
MACHINE=freedom-u540 bitbake demo-coreip-cli
MACHINE=freedom-u540 bitbake demo-coreip-xfce4
```

### Running in QEMU

OE provides easy to use wrapper for QEMU:

```bash
MACHINE=qemuriscv64 runqemu nographic slirp
```

### Running on Hardware

You will find all available build fragments (incl. disk images) in `$BUILDDIR/tmp-glibc/deploy/images/$MACHINE` where `MACHINE` is `freedom-u540` for this particular case.

Disk images files use `<image>-<machine>.<output_format>` format, for example,

`demo-coreip-cli-freedom-u540.wic.gz`. We are interested in `.wic.gz` disk images for writing to uSD card.

> Be very careful while picking /dev/sdX device! Look at dmesg, lsblk, blkid, GNOME Disks, etc. before and after plugging in your uSD card to find a proper device. Double check it to avoid overwriting any of system disks/partitions!
> 
> Unmount any mounted partitions from uSD card before writing!
> 
> We advice to use 16GB or 32GB uSD cards. 8GB cards (shipped with HiFive Unleashed) can still be used with `demo-coreip-cli` CLI images.

Finally write uSD card:

```bash
zcat demo-coreip-cli-freedom-u540.wic.gz | sudo dd of=/dev/sdX bs=512K iflag=fullblock oflag=direct conv=fsync status=progress
```

You will need to modify MSEL to allow using FSBL and OpenSBI + U-Boot bootloaders from uSD card instead of SPI NAND chip:

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

You can login with `root` account. There is no password set for `root` account thus you should set one before continuing.  SSH daemon is started automatically.

## Contributions & Feedback

If you want to file issues, send patches and make feature/enhancement requests use [meta-sifive](https://github.com/sifive/meta-sifive) or [freedom-u-sdk](https://github.com/sifive/freedom-u-sdk) repositories on GitHub.

You are also welcome to join [SiFive Forums ](https://forums.sifive.com/) there we have [HiFive Unleashed](https://forums.sifive.com/c/hifive-unleashed) category for discussions.
