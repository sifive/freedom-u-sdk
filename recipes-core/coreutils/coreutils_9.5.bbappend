PACKAGES:remove = "${PN}-doc"

do_install:append() {
    rm -rf ${D}${datadir}
}
