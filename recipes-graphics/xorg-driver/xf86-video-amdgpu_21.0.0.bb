require recipes-graphics/xorg-driver/xorg-driver-video.inc

LIC_FILES_CHKSUM = "file://COPYING;md5=aabff1606551f9461ccf567739af63dc"

SUMMARY = "X.Org X server -- AMD Radeon video driver"

DESCRIPTION = "Open-source X.org graphics driver for AMD Radeon graphics"

DEPENDS += "virtual/libx11 libxvmc drm \
            virtual/libgl xorgproto libpciaccess"

inherit features_check
REQUIRED_DISTRO_FEATURES += "opengl"

SRC_URI[md5sum] = "61a4af51082a58c63af8970b06c3f4be"
SRC_URI[sha256sum] = "607823034defba6152050e5eb1c4df94b38819ef764291abadd81b620bc2ad88"

RDEPENDS:${PN} += "xserver-xorg-module-exa"
RRECOMMENDS:${PN} += "linux-firmware-radeon"

FILES:${PN} += "${datadir}/X11"
