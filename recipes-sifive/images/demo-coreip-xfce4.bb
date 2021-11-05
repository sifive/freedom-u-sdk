DESCRIPTION = "SiFive RISC-V Core IP Demo Benchmarks Linux image"

IMAGE_FEATURES += "\
    splash \
    ssh-server-openssh \
    tools-sdk \
    tools-debug \
    tools-profile \
    doc-pkgs \
    dev-pkgs \
    nfs-client \
    x11-base \
    hwcodecs"

IMAGE_INSTALL = "\
    packagegroup-core-boot \
    packagegroup-core-full-cmdline \
    kernel-modules \
    kernel-devsrc \
    kernel-dev \
    sysstat \
    dhrystone \
    whetstone \
    iperf3 \
    iperf2 \
    fio \
    tinymembench \
    sysbench \
    memtester \
    lmbench \
    vim \
    nano \
    mc \
    chrony \
    curl \
    wget \
    git \
    bind-utils \
    hexedit \
    pv \
    lsof \
    libgpiod \
    libgpiod-tools \
    libgpiod-dev \
    i2c-tools \
    i2c-tools-misc \
    spitools \
    networkmanager \
    networkmanager-nmcli \
    networkmanager-nmcli-doc \
    networkmanager-nmtui \
    networkmanager-nmtui-doc \
    network-manager-applet \
    haveged \
    e2fsprogs-resize2fs \
    e2fsprogs-e2fsck \
    e2fsprogs-mke2fs \
    gparted \
    parted \
    gptfdisk \
    rsync \
    screen \
    tmux \
    stress-ng \
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
    vulkan-samples \
    xserver-xorg-utils \
    xserver-xorg-xvfb \
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
    linux-firmware \
    quake2 \
    nbd-client \
    mpfr-dev \
    gmp-dev \
    libmpc-dev \
    zlib-dev \
    flex \
    bison \
    dejagnu \
    gettext \
    texinfo \
    procps \
    sln \
    glibc-dev \
    glibc-utils \
    glibc-staticdev \
    elfutils \
    elfutils-dev \
    elfutils-binutils \
    elfutils-staticdev \
    libasm \
    libdw \
    libelf \
    pciutils \
    usbutils \
    devmem2 \
    mtd-utils \
    sysfsutils \
    htop \
    nvme-cli \
    python3 \
    cmake \
    ninja \
    python3-scons \
    libatomic-dev \
    libatomic-staticdev \
    libgomp-dev \
    libgomp-staticdev \
    libstdc++-dev \
    libstdc++-staticdev \
    dtc \
    pcimem \
    jq \
    hdparm \
    udev-extraconf \
    clang \
    clang-dev \
    clang-libllvm \
    clang-staticdev \
    libclang \
    compiler-rt \
    compiler-rt-dev \
    compiler-rt-staticdev \
    ldd \
    libcxx \
    libcxx-dev \
    libcxx-staticdev \
    openmp \
    wireless-regdb-static \
    info \
    gettext-runtime \
    gperf \
    perl-module-locale \
    perl-modules \
    iw \
    gnutls-bin \
    gnutls-dev \
    openssl-bin \
    openssl-dev \
    net-tools \
    man-pages \
    man-db \
    expect \
    gfortran \
    libgfortran \
    libgfortran-dev \
    libgfortran-staticdev \
    gcov \
    gcov-symlinks \
    gcc-symlinks \
    gfortran-symlinks \
    g++-symlinks \
    gcc-plugins \
    gcc-dev \
    cpp-symlinks \
    curl-staticdev \
    dtc-staticdev \
    boost-staticdev \
    libarchive-staticdev \
    bzip2-staticdev \
    lzo-staticdev \
    zlib-staticdev \
    xz-staticdev \
    binutils-staticdev \
    gmp-staticdev \
    libaio-staticdev \
    libatomic-ops-staticdev \
    libbsd-staticdev \
    mpfr-staticdev \
    openmp-staticdev \
    epiphany \
    evince \
    xdg-utils \
    libvdpau \
    gstreamer1.0 \
    mesa-vdpau-drivers \
    vdpauinfo \
    patchelf \
    python3-pip \
    python3-setuptools \
    openssh-misc \
    openssh-sftp \
    openssh-sftp-server \
    lmsensors \
    smartmontools \
    libinput-bin \
    cpupower \
    libubootenv-bin \
    u-boot-tools-mkimage \
    u-boot-tools-mkenvimage \
    xeyes \
    xev \
    xwininfo \
    xvinfo \
    x11perf \
    xdotool \
    tree \
    gdbserver \
    exfat-utils \
    xfsdump \
    xfsprogs \
    xfsprogs-fsck \
    xfsprogs-mkfs \
    xfsprogs-repair \
    btrfs-tools \
    python3-tensorflow-lite \
    python3-tensorflow-lite-demo-doc \
    perf-python \
    ${CORE_IMAGE_EXTRA_INSTALL} \
    "

IMAGE_INSTALL:append:freedom-u540 = " \
    unleashed-udev-rules \
    "

IMAGE_INSTALL:append:unmatched = " \
    unmatched-udev-rules \
    unmatched-systemd-units \
    "

inherit core-image features_check extrausers sifive-wrapping

REQUIRED_DISTRO_FEATURES = "\
    x11 \
    systemd"

EXTRA_USERS_PARAMS = "usermod -p '\$6\$PWVNV6MfuO4pMdqO\$54BibXcgV/nXMrgbaMBioGHNDv1uGVFarQN9QnqM8IMOI/nEwnpB5noxJozigw0lObahcmc3lqTMPvLoSpXnP1' root;"
