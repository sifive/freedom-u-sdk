PACKAGECONFIG:append = " dwarf libunwind manpages jvmti cap"

PACKAGES:remove = "${PN}-doc"

do_install:append() {
    rm -rf ${D}${datadir}
}
