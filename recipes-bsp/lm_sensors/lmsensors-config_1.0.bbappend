FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
  
SRC_URI:append:hifive-premier-p550 = " \
    file://fancontrol \
    "
