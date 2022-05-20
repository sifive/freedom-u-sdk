DESCRIPTION = "A Sample of testing Tensorflow-lite with MNIST handwritten digits."
LICENSE = "CLOSED"

inherit allarch

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://demo/"

do_configure[noexec] = "1"

do_compile[noexec] = "1"

do_install:append() {
    install -d ${D}${docdir}/${PN}/example
    install ${WORKDIR}/demo/* ${D}${docdir}/${PN}/example
}

INHIBIT_DEFAULT_DEPS = "1"

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

FILES:${PN}-doc = "${docdir}/${PN}/example/*"
