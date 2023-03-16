PACKAGECONFIG:append = " python tui xz"

# Temporary workaround for the following build issue:
# file /usr/share/info/sframe-spec.info conflicts between attempted
# installs of binutils-doc-2.40-r0.riscv64 and gdb-doc-13.1-r0.riscv64
do_install:append() {
    rm ${D}${infodir}/sframe-spec.info
}
