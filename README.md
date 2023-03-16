# freedom-u-sdk
SiFive Freedom Unleashed SDK layer for OpenEmbedded/Yocto

## Description

The experimental Freedom Unleashed (FU) SDK is based on OpenEmbedded/Yocto framework, allowing to build custom Linux distributions:
- build predefined disk images for QEMU, [SiFive HiFive Unleashed](https://www.sifive.com/boards/hifive-unleashed) development board and [SiFive HiFive Unmatched](https://www.sifive.com/boards/hifive-unmatched)
- build custom disk images with additional software packages from various third-party OE layers;
- quickly launch QEMU VM instance with your built disk image;
- build bootloader binaries (OpenSBI, U-Boot, U-Boot SPL);
- build Device Tree Binary (DTB);
- build Linux kernel images;
- easily modify disk partition layout.

For more information on particular release see `ReleaseNotes` directory in [freedom-u-sdk](https://github.com/sifive/freedom-u-sdk) repository on GitHub.

For advanced OE usage we advice to look into [Yocto Project Documentation](http://docs.yoctoproject.org/) and [A practical guide to BitBake](https://a4z.gitlab.io/docs/BitBake/guide.html).

## Dependencies

This layer depends on:
* https://github.com/openembedded/bitbake
* https://github.com/openembedded/openembedded-core
* https://git.openembedded.org/meta-openembedded
* https://git.yoctoproject.org/meta-virtualization
* https://github.com/sifive/meta-sifive.git
* https://github.com/kraj/meta-clang.git
* https://github.com/NobuoTsukamoto/meta-tensorflow-lite.git

## Prerequisites for the build host

* [Yocto](https://www.yoctoproject.org/docs/latest/ref-manual/ref-manual.html#required-packages-for-the-build-host)
* [kas](https://kas.readthedocs.io/en/latest/userguide.html#dependencies-installation)

### Create the build environment

```bash
mkdir dist && cd dist
git clone https://github.com/sifive/freedom-u-sdk
```

## Available machines

This layer doesn't define new machines.
It uses machine provides by the `meta-sifive` layer, as well as the Qemu RISC-V
provided by the oe-core layer.

## Available distribution

This layer provides a distribution, named `freedom-u-sdk` for the following machines:
* `freedom-u540`: The SiFive HiFive Unleashed board,
* `unmatched`: The Sifive Unmatched board,
* `qemuriscv64`: The Qemu RISC-V 64bits.

It also provides two disk images:
- `demo-coreip-cli`: basic command line image (**recommended**);
- `demo-coreip-xfce4`: basic graphical disk image with [Xfce 4](https://www.xfce.org/) desktop environment.

## Build images

>
> Building disk images is CPU intensive, could require <10GB of sources
> downloaded over the Internet and <200GB of local storage.

This layer provides Kas scripts configured to download and to configure the
build environment to build `demo-coreip` images for supported targets:

```bash
kas build --update ./freedom-u-sdk/scripts/kas/freedom-u540.yml
kas build --update ./freedom-u-sdk/scripts/kas/qemuriscv64.yml
kas build --update ./freedom-u-sdk/scripts/kas/unmatched.yml
```

Moreover, it is also possible to build other images, or SDK, or also packages,
for example:

```bash
kas build --update ./freedom-u-sdk/scripts/kas/unmatched.yml --target core-image-weston
kas build --update ./freedom-u-sdk/scripts/kas/unmatched.yml --target buildtools-extended-tarball
kas build --update ./freedom-u-sdk/scripts/kas/unmatched.yml --target busybox
kas shell --update ./freedom-u-sdk/scripts/kas/unmatched.yml -c "bitbake core-image-minimal -c populate_sdk"
kas shell --update ./freedom-u-sdk/scripts/kas/unmatched.yml -c "bitbake core-image-minimal -c populate_sdk_ext"
```

## Running in QEMU

The OpenEmbedded/Yocto framework provides a wrapper for QEMU, named `runqemu` in order to use it easily.

Below examples to use this Qemu over a Kas shell:

```bash
kas shell ./freedom-u-sdk/scripts/kas/qemuriscv64.yml -E -c "runqemu slirp nographic demo-coreip-cli"
kas shell ./freedom-u-sdk/scripts/kas/qemuriscv64.yml -E -c "runqemu slirp demo-coreip-xfce4"
```

## Execute runtime tests

The OpenEmbedded/Yocto framework provides also provides tools to implement and to run tests.

These tests can be executed on all supported targets, using the following commands:

```bash
kas build --update ./freedom-u-sdk/scripts/kas/qemuriscv64.yml:./freedom-u-sdk/scripts/kas/include/test.yml
kas shell --update ./freedom-u-sdk/scripts/kas/qemuriscv64.yml:./freedom-u-sdk/scripts/kas/include/test.yml -c "bitbake demo-coreip-cli -c populate_sdk && bitbake demo-coreip-cli -c testsdk"
kas shell --update ./freedom-u-sdk/scripts/kas/qemuriscv64.yml:./freedom-u-sdk/scripts/kas/include/test.yml -c "bitbake demo-coreip-cli -c populate_sdk_ext && bitbake demo-coreip-cli -c testsdkext"
kas shell --update ./freedom-u-sdk/scripts/kas/qemuriscv64.yml:./freedom-u-sdk/scripts/kas/include/test.yml -c "resulttool report  ./tmp/log/oeqa"
```

## Running on Hardware

You will find all available build fragments (incl. disk images) in
`$BUILDDIR/tmp/deploy/images/$MACHINE` where `MACHINE` can be:
- `freedom-u540`
- `qemuriscv64`
- `unmatched`

Disk images files use `<image>-<machine>.<output_format>` format, for example,

`demo-coreip-cli-unmatched.wic.xz`. We are interested in `.wic.xz` disk
images for writing to uSD card.

> Be very careful while picking /dev/sdX device! Look at dmesg, lsblk, blkid,
> GNOME Disks, etc. before and after plugging in your uSD card to find a
> proper device. Double check it to avoid overwriting any of system
> disks/partitions!
>
> Unmount any mounted partitions from uSD card before writing!

### Flash the image on SDCard

Images built can be flashed with `bmaptool` (faster), for example:

```bash
sudo bmaptool copy ../build/tmp/deploy/images/unmatched/demo-coreip-xfce4-unmatched.wic.xz /dev/mmcblk0
```

Otherwise, you can also use the `dd` command, for example:

```bash
xzcat ../build/tmp/deploy/images/unmatched/demo-coreip-xfce4-unmatched.wic.xz | sudo dd of=/dev/mmcblk0 bs=512K iflag=fullblock oflag=direct conv=fsync status=progress
```

### MSEL for Unleashed

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

### MSEL for Unmatched

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

To quit screen, hit `Ctrl - A` followed by `\` symbol. Finally agree to
terminate all windows by typing `y`.

You can login with `root` account. The password is `sifive`. __We strongly
recommend to change the default password  for the root account on the first
boot before you connect it to the Internet.__

### Connecting Using SSH

__Before you connect your board to the Internet we strongly recommend to change
the default password for the root account and configure your network equipment
(for example, routers and firewalls) appropriately.__

SSH daemon is enabled by default, in order to be able to execute remotely
runtime tests. To disable SSH daemon connect to the board using serial console
method described above. Once connected execute the following commands:

```
systemctl disable sshd.socket
systemctl stop sshd.socket
```

The HiFive Unleashed and Unmatched behave like any other network capable
device (such as PC, laptop, and Single Board Computers like Raspberry Pi).
Connect the board to your network (for example, a router), and it will acquire
IPv4 + DNS configuration using DHCP protocol. You can use your router
management panel to get assigned IPv4 address or use the serial console to
acquire it directly from the board (use `ip addr` command to print active
network information). Finally you can SSH to the board:

```
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=no -o "UserKnownHostsFile /dev/null" root@<IPv4>
```

### Supported GPUs

Various GPUs from AMD were successfully tested with the boards. In particular
**Radeon HD 6450** is the most widely used. Other GPUs from the same family
might also work, for instance, THD64xxM, HD7450, HD8450, R5 230, R5 235,
R5 235X. The newest tested GPUs from AMD are RX 550, RX 570, RX 580 with no
issues.

### Online Resizing of rootfs (Root File Partition)

It is highly advised to resize partitions offline (i.e. before booting the
system). If you already booted the system and cannot do offline resizing then
the following instructions should resize rootfs (root file partition) to full
uSD capacity:

```bash
sgdisk -v /dev/mmcblk0
sgdisk -e /dev/mmcblk0
parted /dev/mmcblk0 resizepart 4 100%
resize2fs /dev/mmcblk0p4
sync
```

### NBD (Network Block Device) rootfs

This is an experimantal feature currently only available on SiFive HiFive
Unmatched board. This allow sharing a block device over the network. This is
not an extensive guide into NBD, but a quick start.

If you want to use this feature open `extlinux.conf` in `/boot` partition and
modify the `append` line to:

```
append ip=dhcp root=/dev/nbd0 rw nbdroot=<server_ip_address>:<export_name> nbdport=10809 console=ttySIF0,115200 earlycon
```

If you are booting directly from U-Boot prompt, you would need to set
`bootargs` variable instead.

Note that `<export_name>` value might be ignored by the NBD server (depends on
the implementation and configuration).

`nbdkit` is a recommended NBD server for it's flexibility.

Here is an example command for `nbdkit`:
```
sudo nbdkit -f --verbose --threads 128 --filter=cow --filter=partition --filter=xz file demo-coreip-xfce4-unmatched-<..>.rootfs.wic.xz partition=4
```
This would expose the ext4 filesystem on the 4th partition from XZ compressed
disk image. By default it's read-only thus we also add a COW (Copy-on-Write)
layer. Note that COW layer is not saved by default and will be lost if
`nbdkit` process is terminated. See
[nbdkit-cow-filter](https://libguestfs.org/nbdkit-cow-filter.1.html) NOTES on
how to save disk image with all the modifications for further use.

Using XZ compressed disk image is convenient, but doesn't deliver high
performance. For higher performance uncompress disk image before sharing it
via NBD.

Here is another example:
```
sudo mkdir rootfs
sudo tar -xJ --numeric-owner -C rootfs -f demo-coreip-xfce4-unmatched-<..>.rootfs.tar.xz
sudo nbdkit -f --verbose --threads 128 --filter=partition --filter=cow linuxdisk $PWD/rootfs size=+2G partition=1
```
In this particular case we uncompress rootfs into a directory. We ask `nbdkit`
to take the directory, generate linux disk image from it, add some additional
free space, add a COW layer to make it writable and send "naked" filesystem
(i.e. no partition table) as before.

`nbdkit` has a number of plugins and filters allowing various ways how to share
disk images over the network.

## Run Tensorflow Lite demo

```
cd /usr/share/tensorflow/lite/examples/python/
python3 python3 mnist.py
```

## Contributions & Feedback

If you want to file issues, send patches and make feature/enhancement requests
use [freedom-u-sdk](https://github.com/sifive/freedom-u-sdk) repository on
GitHub. So that the maintainer can process your request.

You are also welcome to join [SiFive Forums ](https://forums.sifive.com/)
where we have [HiFive Unleashed](https://forums.sifive.com/c/hifive-unleashed/12)
and [HiFive Unmatched](https://forums.sifive.com/c/hifive-unmatched/16)
categories for discussions.
