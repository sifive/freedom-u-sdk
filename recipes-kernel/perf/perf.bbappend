PACKAGECONFIG:append = " dwarf libunwind manpages jvmti cap"

PACKAGES:remove = "${PN}-doc"
unset PACKAGECONFIG[jevents]

do_install:append() {
    rm -rf ${D}${datadir}
}
