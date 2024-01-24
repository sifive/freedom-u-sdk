FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

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
