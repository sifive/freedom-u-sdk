DESCRIPTION = "A Sample of testing Tensorflow-lite with MNIST handwritten digits."
LICENSE = "CLOSED"

SRC_URI = "file://demo/"

do_install:append() {
    install -d ${D}${docdir}/${PN}/example
    install ${WORKDIR}/demo/* ${D}${docdir}/${PN}/example
}

FILES:${PN}-doc += "${docdir}/${PN}/example/*"
