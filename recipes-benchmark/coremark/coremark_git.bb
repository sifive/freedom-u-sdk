SUMMARY = "CoreMark performance benchmark"
DESCRIPTION = "CoreMark is an industry-standard benchmark that measures \
the performance of central processing units (CPU) and embedded \
microcrontrollers (MCU)."
HOMEPAGE = "https://www.eembc.org/coremark/"

SECTION = "console/tests"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE.md;md5=0a18b17ae63deaa8a595035f668aebe1"

PR = "r0"

SRC_URI = "git://github.com/eembc/coremark;branch=main;protocol=https"

SRCREV = "d26d6fdcefa1f9107ddde70024b73325bfe50ed2"

PV = "1.0.1+git${SRCREV}"

S = "${WORKDIR}/git"

do_compile() {
    oe_runmake XCFLAGS="-DPERFORMANCE_RUN=1" OUTNAME=coremark_st link

    oe_runmake XCFLAGS="-DPERFORMANCE_RUN=1 -DMULTITHREAD=4 -DUSE_FORK=1" OUTNAME=coremark_mt4 link
}

do_install() {
    install -D -p -m 755 coremark_st ${D}${bindir}/coremark_st
    install -D -p -m 755 coremark_mt4 ${D}${bindir}/coremark_mt4
}

INSANE_SKIP:${PN} = "ldflags"
