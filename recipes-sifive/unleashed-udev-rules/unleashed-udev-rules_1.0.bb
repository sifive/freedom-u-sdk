SUMMARY = "udev rules for SiFive Unleashed"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PR = "r3"

inherit allarch

SRC_URI = "file://99-pwm-leds.rules"

S = "${UNPACKDIR}"

do_configure[noexec] = "1"

do_compile[noexec] = "1"

do_install() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 644 ${UNPACKDIR}/99-pwm-leds.rules ${D}${sysconfdir}/udev/rules.d/99-pwm-leds.rules
}

INHIBIT_DEFAULT_DEPS = "1"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

FILES_${PN} = "${sysconfdir}/udev/rules.d/*"

COMPATIBLE_MACHINE = "(freedom-u540)"
