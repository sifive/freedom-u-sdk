DESCRIPTION = "Tools for working with Chromium development."
HOMEPAGE = "https://www.chromium.org/developers/how-tos/depottools/"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=c2c05f9bdd5fc0b458037c2d1fb8d95e"

PR = "r0"
PV = "1.0+git${SRCPV}"

SRCREV = "3b97fa826eee4bd1978c4c049038b1e4f201e8f2"
SRC_URI = "git://chromium.googlesource.com/chromium/tools/depot_tools.git;protocol=https;branch=main"

S = "${WORKDIR}/git"

inherit native

do_install() {
    install -d ${D}${datadir}/depot_tools
    cp -rTv ${S}/. ${D}${datadir}/depot_tools
}

INSANE_SKIP:${PN} += "already-stripped"
