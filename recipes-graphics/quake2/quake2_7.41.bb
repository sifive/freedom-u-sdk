SUMMARY = "Quake II (Yamagi version)"
DESCRIPTION = "This package contains the enhanced GPL YamagiQuake2 version of \
the Quake 2 engine."
HOMEPAGE = "https://github.com/yquake2/yquake2"
SECTION = "games"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=cdfb10fe3916436d25f4410fcd6a97b8"

inherit pkgconfig

DEPENDS = "mesa libsdl2 libogg libvorbis zlib curl openal-soft"

RDEPENDS:${PN} = " alsa-lib libcurl openal-soft"

SRC_URI = "git://github.com/yquake2/yquake2.git;protocol=https;branch=master \
           file://remove-sse.patch \
           file://disable-unsafe-includes.patch \
           file://fix-unsafe-ldflags.patch \
           file://remove-root-protections.patch \
           file://use-pkg-config.patch"

# Tag: QUAKE2_7_43
SRCREV = "d08cf04d2d5d3ffa0b10eee2e300094571423031"
S = "${WORKDIR}/git"

FILES:${PN} += "${libdir}/games/${PN}/* ${datadir}/icons/hicolor/512x512/apps/${PN}.png"
CONFFILES:${PN} += "${libdir}/games/${PN}/baseq2/yq2.cfg"

do_compile() {
    oe_runmake \
      WITH_SYSTEMWIDE=yes \
      WITH_SYSTEMDIR="${libdir}/games/${PN}"
}

do_install() {
    install -D -p -m 755 release/quake2 ${D}${bindir}/quake2
    install -D -p -m 755 release/q2ded ${D}${bindir}/q2ded
    install -D -p -m 755 release/ref_gl1.so ${D}${bindir}/ref_gl1.so
    install -D -p -m 755 release/ref_gl3.so ${D}${bindir}/ref_gl3.so
    install -D -p -m 755 release/ref_soft.so ${D}${bindir}/ref_soft.so
    install -D -p -m 755 release/q2ded ${D}${bindir}/q2ded
    install -D -p -m 755 release/q2ded ${D}${bindir}/q2ded
    install -D -p -m 755 release/baseq2/game.so ${D}${libdir}/games/${PN}/baseq2/game.so
    install -D -p -m 644 stuff/yq2.cfg ${D}${libdir}/games/${PN}/baseq2/yq2.cfg
    install -D -p -m 644 stuff/icon/Quake2.png ${D}${datadir}/icons/hicolor/512x512/apps/${PN}.png
    install -D -p -m 755 stuff/cdripper.sh ${D}${docdir}/${PN}/examples/cdripper.sh
}
