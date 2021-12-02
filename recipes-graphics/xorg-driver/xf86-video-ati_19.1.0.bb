require recipes-graphics/xorg-driver/xorg-driver-video.inc

LIC_FILES_CHKSUM = "file://COPYING;md5=aabff1606551f9461ccf567739af63dc"

SUMMARY = "X.Org X server -- ATI Radeon video driver"

DESCRIPTION = "Open-source X.org graphics driver for ATI Radeon graphics"

DEPENDS += "virtual/libx11 libxvmc drm \
            virtual/libgl xorgproto libpciaccess"

inherit features_check
REQUIRED_DISTRO_FEATURES += "opengl"

SRC_URI:append = " file://f223035f4ffcff2a9296d1e907a5193f8e8845a3.patch \
                   file://8da3e4561ef82bb78c9a17b8cd8bf139b9cfd680.patch \
                   "

SRC_URI[md5sum] = "6e49d3c2839582af415ceded76e626e6"
SRC_URI[sha256sum] = "659f5a1629eea5f5334d9b39b18e6807a63aa1efa33c1236d9cc53acbb223c49"

RDEPENDS:${PN} += "xserver-xorg-module-exa"
RRECOMMENDS:${PN} += "linux-firmware-radeon"

FILES:${PN} += "${datadir}/X11"
