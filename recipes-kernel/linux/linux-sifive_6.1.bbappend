FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

KBUILD_DEFCONFIG:unmatched = ""

SRC_URI:append:unmatched = " \
    file://defconfig \
"
