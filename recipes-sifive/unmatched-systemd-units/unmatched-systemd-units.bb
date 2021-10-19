SUMMARY = "systemd utils for SiFive HiFive Unmatched"
LICENSE = "GPLv2"
SRC_URI:unmatched = "file://LICENSE.GPL2 \
		     file://led-bootstate-green.timer \
		     file://led-bootstate-green.service"
LIC_FILES_CHKSUM = "file://${WORKDIR}/LICENSE.GPL2;md5=b234ee4d69f5fce4486a80fdaf4a4263"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_PACKAGES = "${PN}"

SYSTEMD_SERVICE:${PN} = "\
    led-bootstate-green.service \
    led-bootstate-green.timer \
"

do_install () {
	if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then	
		install -d ${D}${systemd_system_unitdir}
		install -m 644 ${B}/led-bootstate-green.timer ${D}${systemd_system_unitdir}/led-bootstate-green.timer
		install -m 644 ${B}/led-bootstate-green.service ${D}${systemd_system_unitdir}/led-bootstate-green.service
	fi
}


FILES:${PN} += "${systemd_unitdir}/*"

COMPATIBLE_HOST = "riscv64.*"
COMPATIBLE_MACHINE = "unmatched"
