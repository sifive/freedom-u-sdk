require recipes-sifive/images/demo-coreip-cli.inc

IMAGE_FEATURES += "\
    x11-base \
"

IMAGE_INSTALL += "\
    network-manager-applet \
    packagegroup-core-x11 \
    packagegroup-xfce-base \
    packagegroup-xfce-extended \
    xrandr \
    mesa-demos \
    read-edid \
    mesa-megadriver \
    mesa-vulkan-drivers \
    vulkan-tools \
    vulkan-loader \
    vulkan-headers \
    xserver-xorg-utils \
    xserver-xorg-extension-dbe \
    xserver-xorg-extension-dri \
    xserver-xorg-extension-dri2 \
    xserver-xorg-extension-extmod \
    xserver-xorg-extension-glx \
    xserver-xorg-extension-record \
    python3-ctypes \
    xf86-video-ati \
    xf86-video-amdgpu \
    xf86-video-modesetting  \
    xf86-video-fbdev \
    quake2 \
    epiphany \
    evince \
    xdg-utils \
    libvdpau \
    gstreamer1.0 \
    mesa-vdpau-drivers \
    vdpauinfo \
    libinput-bin \
    xeyes \
    xev \
    xwininfo \
    xvinfo \
    x11perf \
    xdotool \
    glmark2 \
    "

inherit features_check

REQUIRED_DISTRO_FEATURES = "x11 systemd"
IMAGE_ROOTFS_ALIGNMENT:hifive-premier-p550 = "4096"
