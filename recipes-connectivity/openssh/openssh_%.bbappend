# .bb file to update openssh

SUMMARY = "openssh config update"
SECTION = "examples"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://sshd_config"

do_install:append () {
    install -d {D}/etc/ssh
    cp -r ${WORKDIR}/sshd_config ${D}/etc/ssh/sshd_config
}
