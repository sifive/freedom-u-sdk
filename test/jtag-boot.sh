#!/bin/sh

#hack
GDB=work/buildroot_initramfs/host/bin/riscv64-sifive-linux-gnu-gdb
OCD=work/riscv-openocd/src/openocd
UBOOT=$1

if [ ! -f "$UBOOT" ]; then
	echo "file for u-boot at $UBOOT does not exist"
	exit 1
fi

# disabling flash due to reliablility problems
#$OCD -f conf/u540-openocd-flash.cfg &
$OCD -f conf/u540-openocd.cfg &
OCDPID=$!

#nc <<EOF
#reset halt
#load_image work/HiFive_U-Boot/u-boot.bin 0x08000000 bin
#reg pc 0x08000000
#resume

sleep 0.5

$GDB << EOF &
set remotetimeout 240
target extended-remote localhost:3333
shell sleep 1
monitor reset halt
info thread
#restore work/HiFive_U-Boot/u-boot.bin 0x08000000
monitor load_image $UBOOT 0x08000000
thread apply all set \$pc=0x08000000
continue
EOF

GDBPID=$!

sleep 10
kill $OCDPID

wait
