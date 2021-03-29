# SiFive Freedom Unleashed SDK

The new experimental Freedom Unleashed (FU) SDK is based on OpenEmbedded (OE). It's a minimal [meta-sifive](https://github.com/sifive/meta-sifive) layer on top of [meta-riscv](https://github.com/riscv/meta-riscv) to provide additional modifications and new disk image targets. Using OE you will be able to:

- build predefined disk images for QEMU, [SiFive HiFive Unleashed](https://www.sifive.com/boards/hifive-unleashed) development board (incl. [HiFive Unleashed Expansion Board](https://www.crowdsupply.com/microsemi/hifive-unleashed-expansion-board) from Microsemi) and [SiFive HiFive Unmatched](https://www.sifive.com/boards/hifive-unmatched);
	+ __Note__: We are deprecating support for HiFive Unleashed Expansion board from Microsemi, and future releases will remove support for it from SiFive OpenEmbedded layer (i.e. [meta-sifive](https://github.com/sifive/meta-sifive)). If you have the expansion board we advice you to switch to [Microchip PolarFire SoC Yocto BSP](https://github.com/polarfire-soc/meta-polarfire-soc-yocto-bsp/) which includes support for MPFS-DEV-KIT (HiFive Unleashed Expansion Board) directly from the manufacturer. You are also welcome to use older releases (2021.02.00 or older) from SiFive OpenEmbedded layer.
	+ __Note:__  2021.02.00 release introduces the support for the SiFive HiFive Unmatched board __(pre-production 8GB variant)__. Contact your SiFive representative before using disk images built for `unmatched` machine on your particular board. If you received the __final board (16GB) variant__ via Mouser or CrowdSupply you should skip 2021.02.00 release and use 2021.03.00 (or newer).
- build custom disk images with additional software packages from various third-party OE layers;
- quickly launch QEMU VM instance with your built disk image;
- build bootloader binaries (OpenSBI, U-Boot, U-Boot SPL);
- build Device Tree Binary (DTB);
- build Linux kernel images;
- easily modify disk partition layout.

For more information on particular release see `ReleaseNotes` directory in [freedom-u-sdk](https://github.com/sifive/freedom-u-sdk) repository on GitHub.

The old SDK based on Buildroot is archived in [`archive/buildroot`](https://github.com/sifive/freedom-u-sdk/tree/archive/buildroot) branch.

For advanced OE usage we advice to look into [Yocto Project Documentation](http://docs.yoctoproject.org/) and [A practical guide to BitBake](https://a4z.gitlab.io/docs/BitBake/guide.html).

## Quick Start

Install `repo` command from Google if not available on your host system. Please follow [the official instructions](https://source.android.com/setup/develop#installing-repo) by Google.

Then install a number of packages for BitBake (OE build tool) to work properly on your host system. BitBake itself depends on Python 3. Once you have Python 3 installed BitBake should be able to tell you most of the missing packages.

> For Ubuntu 18.04 (or newer) install python3-distutils package.

Detailed instructions for various distributions can be found in "[Required Packages for the Build Host](http://docs.yoctoproject.org/ref-manual/system-requirements.html#required-packages-for-the-build-host)" section in Yocto Project Reference Manual.

### Creating Workspace

This needs to be done every time you want a clean setup based on the latest layers.

```bash
mkdir riscv-sifive && cd riscv-sifive
repo init -u git://github.com/sifive/meta-sifive -b 2021.03 -m tools/manifests/sifive.xml
repo sync
```

### Creating a Working Branch

If you want to make modifications to existing layers then creating working branches in all repositories is advisable.

```bash
repo start work --all
```

### Getting Build Tools (optional)

OpenEmbedded-Core requires GCC 6 or newer to be available on the host system. Your host system might have an older version of GCC if you use LTS (Long Term Support) Linux distribution (e.g. Ubuntu 16.04.6 has GCC 5.4.0). You could solve this issue by installing build tools. This requires less than 400MB of disk space. You can download pre-built one or build your own build tools.

#### Option 1: Installing OpenEmbedded-Core Build Tools (Pre-Built)

```bash
./openembedded-core/scripts/install-buildtools -r yocto-3.2_M2 -t 20200729
```

The native SDK will be installed under `$BUILDDIR/../openembedded-core/buildtools` prefix.

Finally you should be able to use build tools:

```bash
. ./openembedded-core/buildtools/environment-setup-x86_64-pokysdk-linux
```

#### Option 2: Building Your Own Build Tools

> Your host needs to have GCC 6 (or newer) or build tools installed from Option 1.

> You can find pre-built tools from the same release source in GitHub release assets.

To build your own build tools execute the command below:

```bash
bitbake buildtools-extended-tarball
```

You can find the native SDK under `$BUILDDIR/tmp-glibc/deploy/sdk/` directory.

Now you can install build tools:

```bash
$BUILDDIR/tmp-glibc/deploy/sdk/x86_64-buildtools-extended-nativesdk-standalone-nodistro.0.sh -d $BUILDDIR/../openembedded-core/buildtools -y
```

Finally you should be able to use your build tools:

```bash
. $BUILDDIR/../openembedded-core/buildtools/environment-setup-x86_64-oesdk-linux
```

### Setting up Build Environment

This step has to be done after you modify your environment with toolchain you want to use otherwise wrong host tools might be available in the package build environment. For example, `gcc` from host system will be used for building `*-native` packages.

```bash
. ./meta-sifive/setup.sh
```

> You can verify and fix your host tools by checking symlinks in `$BUILDDIR/tmp-glibc/hosttools` directory.

### Configuring BitBake Parallel Number of Tasks/Jobs

There are 3 variables that control the number of parallel tasks/jobs BitBake will use: `BB_NUMBER_PARSE_THREADS`, `BB_NUMBER_THREADS` and `PARALLEL_MAKE`. The last two are the most important, and both are set to number of cores available on the system. You can set them in your `$BUILDDIR/conf/local.conf` or in your shell environment similar to how `MACHINE` is used (see next section). Example:

```bash
PARALLEL_MAKE="-j 4" BB_NUMBER_THREADS=4 MACHINE=freedom-u540 bitbake demo-coreip-cli
```

Leaving defaults could cause high load averages, high memory usage, high IO wait and could make your system unresponsive due to resources overuse. The defaults should be changed based on your system configuration.

### Building Disk Images

There are two disk image targets added by meta-sifive layer:

- `demo-coreip-cli` - basic command line image (**recommended**);

- `demo-coreip-xfce4` - basic graphical disk image with [Xfce 4](https://www.xfce.org/) desktop environment.

By default disk images do not include debug packages. If you want to produce disk images with debug packages append `-debug` (e.g. `demo-coreip-cli-debug`) to the disk image target.

There are two machine targets currently tested:

- `qemuriscv64` - RISC-V 64-bit (RV64GC) for QEMU virt machine.

- `freedom-u540` - SiFive HiFive Unleashed development board with or without HiFive Unleashed Expansion Board from Microsemi.

- `unmatched` - SiFive HiFive Unmatched development board.

> It's not possible to use disk images built for `freedom-u540` with QEMU 4.0 and instructions provided below.
> 
> Building disk images is CPU intensive, could require <10GB of sources downloaded over the Internet and <200GB of local storage.

Building disk image takes a single command which may take anything from 30 minutes to several hours depending on your hardware. Examples:

```bash
MACHINE=qemuriscv64 bitbake demo-coreip-cli
MACHINE=freedom-u540 bitbake demo-coreip-cli
MACHINE=freedom-u540 bitbake demo-coreip-xfce4
MACHINE=unmatched bitbake demo-coreip-xfce4
```

### Running in QEMU

OE provides easy to use wrapper for QEMU:

```bash
MACHINE=qemuriscv64 runqemu nographic slirp
```

### Running on Hardware

You will find all available build fragments (incl. disk images) in `$BUILDDIR/tmp-glibc/deploy/images/$MACHINE` where `MACHINE` is `freedom-u540` or `unmatched`.

Disk images files use `<image>-<machine>.<output_format>` format, for example,

`demo-coreip-cli-freedom-u540.wic.xz`. We are interested in `.wic.xz` disk images for writing to uSD card.

> Be very careful while picking /dev/sdX device! Look at dmesg, lsblk, blkid, GNOME Disks, etc. before and after plugging in your uSD card to find a proper device. Double check it to avoid overwriting any of system disks/partitions!
> 
> Unmount any mounted partitions from uSD card before writing!
> 
> We advice to use 32GB uSD cards. 8GB cards (shipped with HiFive Unleashed) can still be used with `demo-coreip-cli` CLI images.

Finally write uSD card:

```bash
xzcat demo-coreip-cli-freedom-u540.wic.xz | sudo dd of=/dev/sdX bs=512K iflag=fullblock oflag=direct conv=fsync status=progress
```

#### MSEL for Unleashed

You will need to modify MSEL to allow using U-Boot SPL, OpenSBI, U-Boot proper bootloaders from uSD card instead of SPI-NOR Flash chip:

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

#### MSEL for Unmatched

By default MSEL on Unmatched is set to use uSD instead of SPI-NOR Flash chip to load U-Boot SPL, OpenSBI and U-Boot proper. Below is the default configuration for DIP switches (located next to Assembly Number and RTC battery):

```
  +----------> CHIPIDSEL
  | +--------> MSEL3
  | | +------> MSEL2
  | | | +----> MSEL1
  | | | | +--> MSEL0
  | | | | |
 +-+-+-+-+-+
 | |X| |X|X| ON(1)
 | | | | | |
 |X| |X| | | OFF(0)
 +-+-+-+-+-+
BOOT MODE SEL

```


### Connecting Using Serial Console

Connect your HiFive Unleashed or HiFive Unmatched to your PC using microUSB-USB cable to access serial console.

For macOS, run: `screen -L /dev/tty.usbserial-*01 115200`

For Linux, run: `screen -L /dev/serial/by-id/usb-FTDI_Dual_RS232-HS-if01-port0 115200`

The above commands might vary depending on your exact setup.

`-L` command will log all output to `screenlog.0` in your current working directory.

To quit screen, hit `Ctrl - A` followed by `\` symbol. Finally agree to terminate all windows by typing `y`.

You can login with `root` account. The password is `sifive`. __We strongly recommend to change the default password  for the root account on the first boot before you connect it to the Internet.__

### Connecting Using SSH

__Before you connect your board to the Internet we strongly recommend to change the default password for the root account and configure your network equipment (for example, routers and firewalls) appropriately.__

SSH daemon is not enabled by default. To enable SSH daemon connect to the board using serial console method described above. Once connected execute the following commands:

```
systemctl enable sshd.socket
systemctl start sshd.socket
```

The HiFive Unleashed and Unmatched behave like any other network capable device (such as PC, laptop, and Single Board Computers like Raspberry Pi). Connect the board to your network (for example, a router), and it will acquire IPv4 + DNS configuration using DHCP protocol. You can use your router management panel to get assigned IPv4 address or use the serial console to acquire it directly from the board (use `ip addr` command to print active network information). Finally you can SSH to the board:

```
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=no -o "UserKnownHostsFile /dev/null" root@<IPv4>
```

### Supported GPUs

Various GPUs from AMD were successfully tested with the boards. In particular **Radeon HD 6450** is the most widely used. Other GPUs from the same family might also work, for instance, THD64xxM, HD7450, HD8450, R5 230, R5 235, R5 235X. The newest tested GPUs from AMD are RX 550, RX 570, RX 580 with no issues.

For HiFive Unleashed with HiFive Expansion Board from Microsemi we advice to use Radeon HD 6450 or RX 550. These cards were tested with power supply (12V 5A) which came with the expansion board.

### Online Resizing of rootfs (Root File Partition)

It is highly advised to resize partitions offline (i.e. before booting the system). If you already booted the system and cannot do offline resizing then the following instructions should resize rootfs (root file partition) to full uSD capacity:

```bash
sgdisk -v /dev/mmcblk0
sgdisk -e /dev/mmcblk0
parted /dev/mmcblk0 resizepart 4 100%
resize2fs /dev/mmcblk0p4
sync
```

## Contributions & Feedback

If you want to file issues, send patches and make feature/enhancement requests use [meta-sifive](https://github.com/sifive/meta-sifive) or [freedom-u-sdk](https://github.com/sifive/freedom-u-sdk) repositories on GitHub.

You are also welcome to join [SiFive Forums ](https://forums.sifive.com/) where we have [HiFive Unleashed](https://forums.sifive.com/c/hifive-unleashed/12) and [HiFive Unmatched](https://forums.sifive.com/c/hifive-unmatched/16) categories for discussions.

## Known Issues

1. Avoid overclocking SOC using CPUFreq if you are using HiFive Unleashed Expansion Board from Microsemi as this will hang the board. Hard reset will be required.

2. There is no CPUFreq support enabled on HiFive Unmatched.

3. If Xfce4 desktop disk image is used with HiFive Unleashed Expansion Board and GPU then rebooting is required after the 1st boot.

4. OpenEmbedded Core (and thus meta-sifive) does not support eCryptFS or any other file system without long file names support. File systems must support filenames up to 200 characters in length.

5. BitBake requires UTF-8 based locale (e.g. `en_US.UTF-8`). You can choose any locale as long as it is UTF-8. This usually happens in containers (e.g. ubuntu:18.04). You can verify your locale by running `locale` command. On Ubuntu 18.04 you can change locale following these instructions:
   
   ```bash
   apt update
   apt install locales
   locale-gen en_US.UTF-8
   update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
   export LANG="en_US.UTF-8"
   locale
   ```
   
   You can change system default locale with `dpkg-reconfigure locales` command.
