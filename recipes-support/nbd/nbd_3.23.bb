DESCRIPTION = "Network Block Device"
HOMEPAGE = "http://nbd.sourceforge.net"
SECTION = "net"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

DEPENDS = "glib-2.0 bison-native libnl"

SRC_URI = "${SOURCEFORGE_MIRROR}/${BPN}/${BPN}-${PV}.tar.xz"
SRC_URI[md5sum] = "c35397bd2c4d53bb9f14523463357096"
SRC_URI[sha256sum] = "def470ec566ac4e3a34d56f391f0a670e520e1bc2eedd67eba62f454418457b4"

inherit autotools pkgconfig

PACKAGES = "${PN}-client ${PN}-server ${PN}-dbg ${PN}-trdump ${PN}-doc"

FILES:${PN}-client = "${sbindir}/${BPN}-client"
FILES:${PN}-server = "${bindir}/${BPN}-server"
FILES:${PN}-trdump = "${bindir}/${BPN}-trdump"
