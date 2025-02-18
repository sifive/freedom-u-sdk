FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://add-tmp451-chip.patch \
    "

SYSTEMD_AUTO_ENABLE:hifive-premier-p550 = "enable"
