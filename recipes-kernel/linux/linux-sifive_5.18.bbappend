FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

KBUILD_DEFCONFIG:unmatched = ""

SRC_URI:append:unmatched = " \
    file://defconfig \
    file://0001-drm-radeon-avoid-bogus-vram-limit-0-must-be-a-power-.patch \
"
