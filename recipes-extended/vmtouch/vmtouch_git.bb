SUMMARY = "the Virtual Memory Toucher"
DESCRIPTION = "vmtouch is a tool for learning about and controlling the file system cache of unix and unix-like systems. It is BSD licensed so you can basically do whatever you want with it."
HOMEPAGE = "https://hoytech.com/vmtouch/"
LICENSE = "BSD-3-Clause"
SECTION = "console/utils"

LIC_FILES_CHKSUM = "file://LICENSE;md5=ea4594d5258fd05f3b214aa3cea63837"

inherit perlnative

SRCREV = "8f6898e3c027f445962e223ca7a7b33d40395fc6"
BRANCH = "master"
PV = "v1.3.1+git${SRCPV}"

S = "${WORKDIR}/git"

SRC_URI = "git://github.com/hoytech/vmtouch;protocol=https;branch=${BRANCH}"

do_install() {
    oe_runmake DESTDIR=${D} PREFIX=${prefix} install
}
