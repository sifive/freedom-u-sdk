PACKAGES:remove = "${PN}-client"
PACKAGES:remove = "${PN}-server"

RDEPENDS:${PN} = "${PN}-proxy (>= ${PV})"
