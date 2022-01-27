DESCRIPTION = "Tool to query the capabilities of a VDPAU implementation"
HOMEPAGE = "https://gitlab.freedesktop.org/vdpau/vdpauinfo"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://COPYING;md5=5b6e110c362fe46168199f3490e52c3c"

SRC_URI = "git://people.freedesktop.org/~aplattner/vdpauinfo;branch=master"
S = "${WORKDIR}/git"
SRCREV = "3463ab40a89179e6e199575e8bee9c23ee027377"

inherit autotools pkgconfig

DEPENDS += "libvdpau"

RDEPENDS:${PN} += "libvdpau"
