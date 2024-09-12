PACKAGECONFIG:append:freedom-u-sdk = " autospawn-for-root"
PACKAGECONFIG:append:freedom-u-sdk-hf-premier-p550 = " autospawn-for-root"

FILESEXTRAPATHS:prepend:hifive-premier-p550 := "${THISDIR}/files:"

SRC_URI:append:hifive-premier-p550 = " file://0001-Update-default-configuration.patch"
