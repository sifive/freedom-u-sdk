
srcdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
srcdir := $(srcdir:/=)
confdir := $(srcdir)/conf
wrkdir := $(CURDIR)/work

buildroot_srcdir := $(srcdir)/buildroot
buildroot_wrkdir := $(wrkdir)/buildroot
buildroot_tar := $(buildroot_wrkdir)/images/rootfs.tar

sysroot_stamp := $(wrkdir)/.sysroot
sysroot := $(wrkdir)/sysroot

linux_srcdir := $(srcdir)/linux
linux_wrkdir := $(wrkdir)/linux
linux_defconfig := $(confdir)/linux_defconfig

vmlinux := $(linux_wrkdir)/vmlinux
vmlinux_stripped := $(linux_wrkdir)/vmlinux-stripped

pk_srcdir := $(srcdir)/riscv-pk
pk_wrkdir := $(wrkdir)/riscv-pk
bbl := $(pk_wrkdir)/bbl
bin := $(wrkdir)/bbl.bin

target := riscv64-unknown-linux-gnu

.PHONY: all
all: $(bin)

$(buildroot_tar): $(buildroot_srcdir)
	$(MAKE) -C $< O=$(buildroot_wrkdir) riscv64_defconfig
	$(MAKE) -C $< O=$(buildroot_wrkdir)

.PHONY: buildroot-menuconfig
buildroot-menuconfig: $(buildroot_srcdir)
	$(MAKE) -C $< O=$(buildroot_wrkdir) menuconfig

$(sysroot_stamp): $(buildroot_tar)
	mkdir -p $(sysroot)
	tar -xpf $< -C $(sysroot) --exclude ./dev
	touch $@

$(linux_wrkdir)/.config: $(linux_defconfig) $(linux_srcdir)
	mkdir -p $(dir $@)
	cp -p $< $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) ARCH=riscv olddefconfig

$(vmlinux): $(linux_srcdir) $(linux_wrkdir)/.config $(sysroot_stamp)
	$(MAKE) -C $< O=$(linux_wrkdir) \
		CONFIG_INITRAMFS_SOURCE="$(confdir)/initramfs.txt $(sysroot)" \
		CONFIG_INITRAMFS_ROOT_UID=$(shell id -u) \
		CONFIG_INITRAMFS_ROOT_GID=$(shell id -g) \
		ARCH=riscv \
		vmlinux

$(vmlinux_stripped): $(vmlinux)
	$(target)-strip -o $@ $<

.PHONY: linux-menuconfig
linux-menuconfig: $(linux_wrkdir)/.config
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv menuconfig savedefconfig

$(bbl): $(pk_srcdir) $(vmlinux_stripped)
	rm -rf $(pk_wrkdir)
	mkdir -p $(pk_wrkdir)
	cd $(pk_wrkdir) && $</configure \
		--host=$(target) \
		--with-payload=$(vmlinux_stripped)
	$(MAKE) -C $(pk_wrkdir)

$(bin): $(bbl)
	$(target)-objcopy -S -O binary --change-addresses -0x80000000 $< $@

.PHONY: sysroot vmlinux bbl
sysroot: $(sysroot)
vmlinux: $(vmlinux)
bbl: $(bbl)

.PHONY: clean
clean:
	rm -rf -- $(wrkdir)
