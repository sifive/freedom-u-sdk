FILESEXTRAPATHS:prepend := "${THISDIR}/${P}:"

KBUILD_DEFCONFIG:unmatched = ""

SRC_URI:append:unmatched = " \
    file://defconfig \
"
