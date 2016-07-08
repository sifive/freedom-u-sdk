
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
linux_release := linux-4.6.2.tar.xz
linux_url := ftp://ftp.kernel.org/pub/linux/kernel/v4.x

vmlinux := $(linux_wrkdir)/vmlinux
vmlinux_stripped := $(linux_wrkdir)/vmlinux-stripped

pk_srcdir := $(srcdir)/riscv-pk
pk_wrkdir := $(wrkdir)/riscv-pk
bbl := $(pk_wrkdir)/bbl
bin := $(wrkdir)/bbl.bin
hex := $(wrkdir)/bbl.hex

target := riscv64-unknown-linux-gnu

.PHONY: all
all: $(hex)

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

$(linux_release):
	curl -O $(linux_url)/$(linux_release)

$(linux_wrkdir)/.config: $(linux_defconfig) $(linux_srcdir) $(linux_release)
	mkdir -p $(dir $@)
	cp -p $< $@
	cd $(linux_srcdir); tar --strip-components=1 -xJf ../$(linux_release); git checkout .gitignore arch/.gitignore
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

$(hex):	$(bin)
	xxd -c1 -p $< > $@

.PHONY: sysroot vmlinux bbl
sysroot: $(sysroot)
vmlinux: $(vmlinux)
bbl: $(bbl)

.PHONY: clean
clean:
	rm -rf -- $(wrkdir)
