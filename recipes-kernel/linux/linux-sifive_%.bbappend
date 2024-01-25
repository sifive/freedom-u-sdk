FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:riscv64 = " file://0001-riscv-dts-sifive-unmatched-keep-leds-settings.patch"

KERNEL_FEATURES:append:riscv64 = " \
    cfg/sound.scc \
    cfg/usb-mass-storage.scc \
    features/bluetooth/bluetooth-usb.scc \
    features/bluetooth/bluetooth-vhci.scc \
    features/input/input.scc \
    features/leds/leds.scc \
    features/netfilter/netfilter.scc \
    features/nfsd/nfsd-enable.scc \
    features/rfkill/rfkill.scc \
    features/wifi/wifi-all.scc \
"
