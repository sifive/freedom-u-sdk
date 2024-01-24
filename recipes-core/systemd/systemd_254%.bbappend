# To use NetworkManager instead
PACKAGECONFIG:remove = "networkd nss-resolve resolved"

PACKAGECONFIG:append = " cgroupv2"
