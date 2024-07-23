FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://add-tmp451-chip.patch \
    "

SRC_URI:append:hifive-premier-p550 = " \
    file://0001-hifive-premier-fancontrol-Changed-max-pwm-level-to-9.patch \
    "

SYSTEMD_AUTO_ENABLE:hifive-premier-p550 = "enable"
