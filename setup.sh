#!/bin/bash
# Bootstrapper for buildbot slave

DIR="build"
MACHINE="unmatched"
CONFFILE="conf/auto.conf"
BITBAKEIMAGE="demo-coreip-xfce4"

# clean up the output dir
#echo "Cleaning build dir"
#rm -rf $DIR

# make sure sstate is there
#echo "Creating sstate directory"
#mkdir -p ~/sstate/$MACHINE

# fix permissions set by buildbot
#echo "Fixing permissions for buildbot"
#umask -S u=rwx,g=rx,o=rx
#chmod -R 755 .

# Reconfigure dash on debian-like systems
which aptitude > /dev/null 2>&1
ret=$?
if [ "$(readlink /bin/sh)" = "dash" -a "$ret" = "0" ]; then
  sudo aptitude install expect -y
  expect -c 'spawn sudo dpkg-reconfigure -freadline dash; send "n\n"; interact;'
elif [ "${0##*/}" = "dash" ]; then
  echo "dash as default shell is not supported"
  return
fi
# bootstrap OE
echo "Init OE"
export BASH_SOURCE="openembedded-core/oe-init-build-env"
. ./openembedded-core/oe-init-build-env $DIR

if [ -e $CONFFILE ]; then
    echo "Your build directory already has local configuration file!"
    echo "If you want to start from scratch remove old build directory:"
    echo ""
    echo "    rm -rf $PWD"
    echo ""
else

# Symlink the cache
#echo "Setup symlink for sstate"
#ln -s ~/sstate/${MACHINE} sstate-cache

# add the missing layers
echo "Adding layers"
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer ../meta-openembedded/meta-python
bitbake-layers add-layer ../meta-openembedded/meta-multimedia
bitbake-layers add-layer ../meta-openembedded/meta-filesystems
bitbake-layers add-layer ../meta-openembedded/meta-networking
bitbake-layers add-layer ../meta-openembedded/meta-gnome
bitbake-layers add-layer ../meta-openembedded/meta-xfce
bitbake-layers add-layer ../meta-riscv
bitbake-layers add-layer ../meta-clang
bitbake-layers add-layer ../meta-sifive
bitbake-layers add-layer ../meta-tensorflow-lite/

# fix the configuration
echo "Creating auto.conf"

#if [ -e $CONFFILE ]; then
#    rm -rf $CONFFILE
#fi
cat <<EOF > $CONFFILE
MACHINE ?= "${MACHINE}"
#IMAGE_FEATURES += "tools-debug"
#IMAGE_FEATURES += "tools-tweaks"
#IMAGE_FEATURES += "dbg-pkgs"
# rootfs for debugging
#IMAGE_GEN_DEBUGFS = "1"
#IMAGE_FSTYPES_DEBUGFS = "tar.gz"
#EXTRA_IMAGE_FEATURES:append = " ssh-server-dropbear"
EXTRA_IMAGE_FEATURES:append = " package-management"
PACKAGECONFIG:append:pn-qemu-native = " sdl"
PACKAGECONFIG:append:pn-nativesdk-qemu = " sdl"
USER_CLASSES ?= "buildstats buildhistory buildstats-summary image-prelink"

require conf/distro/include/yocto-uninative.inc
require conf/distro/include/security_flags.inc

INHERIT += "uninative"

DISTRO_FEATURES:append = " largefile opengl ptest multiarch pam systemd vulkan "
DISTRO_FEATURES_BACKFILL_CONSIDERED += "sysvinit"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = ""
VIRTUAL-RUNTIME_syslog = ""
VIRTUAL-RUNTIME_login_manager = "shadow-base"
HOSTTOOLS_NONFATAL:append = " ssh"

PREFERRED_PROVIDER_base-utils = "packagegroup-core-base-utils"
VIRTUAL-RUNTIME_base-utils = "packagegroup-core-base-utils"
VIRTUAL-RUNTIME_base-utils-hwclock = "util-linux-hwclock"
VIRTUAL-RUNTIME_base-utils-syslog = ""

# Use full features vim instead of vim-tiny
VIRTUAL-RUNTIME_vim = "vim"

# We use NetworkManager instead
PACKAGECONFIG:remove:pn-systemd = "networkd"

SECURITY_CFLAGS:pn-opensbi = ""
SECURITY_LDFLAGS:pn-opensbi = ""

# Add r600 drivers for AMD GPU
PACKAGECONFIG:append:pn-mesa = " r600"

# Add support for modern AMD GPU (e.g. RX550 / POLARIS)
PACKAGECONFIG:append:pn-mesa = " radeonsi"
PACKAGECONFIG:append:pn-mesa = " gallium-llvm"
PACKAGECONFIG:append:pn-mesa = " vdpau"

PACKAGECONFIG:append:pn-gdb = " python"
PACKAGECONFIG:append:pn-gdb = " tui"
PACKAGECONFIG:append:pn-gdb = " xz"

PACKAGECONFIG:append:pn-elfutils = " bzip2"
PACKAGECONFIG:append:pn-elfutils = " xz"

PACKAGECONFIG:append:pn-pulseaudio = " autospawn-for-root"

PACKAGECONFIG:append:pn-mousepad = " spell"

PACKAGECONFIG:append:pn-perf = " dwarf"
PACKAGECONFIG:append:pn-perf = " libunwind"
PACKAGECONFIG:append:pn-perf = " manpages"
PACKAGECONFIG:append:pn-perf = " jvmti"
PACKAGECONFIG:append:pn-perf = " cap"

QEMU_TARGETS = "riscv64 x86_64"

CLANGSDK = "1"

FORTRAN:forcevariable = ",fortran"

BBMASK += "openembedded-core/meta/recipes-bsp/opensbi/opensbi_0.9.bb"

DISTRO_NAME = "FreedomUSDK"
DISTRO_VERSION = "2021.10.00"
DISTRO_CODENAME = "2021October"
EOF
fi

echo "---------------------------------------------------"
echo "Example: MACHINE=${MACHINE} bitbake ${BITBAKEIMAGE}"
echo "---------------------------------------------------"
echo ""
echo "Buildable machine info"
echo "---------------------------------------------------"
echo "* unmatched         : The SiFive HiFive Unmatched board"
echo "* freedom-u540      : The SiFive HiFive Unleashed board"
echo "* qemuriscv64       : The 64-bit RISC-V machine"
echo "* qemuriscv64_b     : The 64-bit RISC-V machine with B-ext"
echo "* qemuriscv64_b_zfh : The 64-bit RISC-V machine with B and Zfh-ext"
echo "* qemuriscv64_v     : The 64-bit RISC-V machine with V-ext"
echo "---------------------------------------------------"

# start build
#echo "Starting build"
#bitbake $BITBAKEIMAGE

