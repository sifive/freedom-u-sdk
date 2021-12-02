DESCRIPTION = "SiFive RISC-V Core IP Demo Benchmarks Linux image"

# Simple initramfs image. Mostly used for live images.
DESCRIPTION = "Small image capable of booting a device. The kernel includes \
the Minimal RAM-based Initial Root Filesystem (initramfs), which finds the \
first 'init' program more efficiently."

INITRAMFS_SCRIPTS ?= "\
		initramfs-framework-base \
		initramfs-module-nfsrootfs \
		initramfs-module-nbdrootfs \
		initramfs-module-udev \
		initramfs-module-e2fs \
                "

PACKAGE_INSTALL = "${INITRAMFS_SCRIPTS} busybox base-passwd udev nbd-client"

IMAGE_FEATURES:append = " nfs-client"

IMAGE_INSTALL:append = " nbd-client"

export IMAGE_BASENAME = "${MLPREFIX}demo-coreip-cli-initramfs"
IMAGE_NAME_SUFFIX ?= ""
IMAGE_LINGUAS = ""

LICENSE = "MIT"

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"
inherit core-image

IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

# Use the same restriction as initramfs-module-install
#COMPATIBLE_HOST = '(x86_64.*|i.86.*|riscv64.*|arm.*|aarch64.*)-(linux.*|freebsd.*)'
