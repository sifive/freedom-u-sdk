DESCRIPTION = "Experimental Core IP benchmarks"

IMAGE_FEATURES += "\
    splash \
    ssh-server-openssh \
    tools-sdk \
    tools-debug \
    tools-profile \
    doc-pkgs \
    dev-pkgs \
    dbg-pkgs \
    nfs-client \
    nfs-server"

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
    coremark \
    vim \
    nano \
    mc \
    chrony \
    curl \
    wget \
    git \
    bind-utils \
    networkmanager \
    networkmanager-nmtui \
    networkmanager-nmtui-doc \
    e2fsprogs-resize2fs \
    e2fsprogs-e2fsck \
    e2fsprogs-mke2fs \
    parted \
    gptfdisk \
    rsync \
    screen \
    tmux \
    ${CORE_IMAGE_EXTRA_INSTALL} \
    "

inherit core-image
