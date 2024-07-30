# To use NetworkManager instead
PACKAGECONFIG:remove = "networkd nss-resolve resolved"

# Temporary build issue workaround
PACKAGECONFIG:remove = "cgroupv2"
