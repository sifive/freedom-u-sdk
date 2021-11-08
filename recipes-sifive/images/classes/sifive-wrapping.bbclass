DEPENDS += "coreutils-native xz-native dtc-native"

generate_machine_settings() {
    # Setup defaults
    arch=rv64i
    abi=lp64
    cmodel=medany
    series=None

    # parse various elements of the device tree file
    while read dtlin
    do
        case ${dtlin} in
        (*riscv,isa*=*rv64*)
            isa=$(echo "${dtlin}" | cut -d \" -f 2)
            if [ ${#isa} -gt ${#arch} ]
            then
                arch=${isa}
            fi
            ;;
        (*compatible*=*rocket*)
            series=sifive-5-series
            ;;
        (*compatible*=*bullet*)
            series=sifive-7-series
            ;;
        (*compatible*=*mallard*)
            series=sifive-8-series
            ;;
        (*)
        esac
    done < ./design.dts

    # split isa string into general (before _) and special (after _) parts
    general=${arch%%_*}
    special=${arch#${general}}
    # qemu adds s to the isa string which the compilers doesn't like
    if [ ${general} != ${general%%s*} ]
    then
        general=$(echo "${general}" | tr -d s)
    fi
    # qemu adds u to the isa string which the compilers doesn't like
    if [ ${general} != ${general%%u*} ]
    then
        general=$(echo "${general}" | tr -d u)
    fi
    # qemu adds b to the isa string which the compilers doesn't like
    if [ ${general} != ${general%%b*} ]
    then
        general=$(echo "${general}" | tr -d b)_zba_zbb
    fi
    # merge general and special parts again
    if [ ${arch} != ${special} ]
    then
        arch=${general}${special}
    else
        arch=${general}
    fi
    # set abi based on isa general part
    if [ ${general} != ${general%%d*} ]
    then
        abi=lp64d
    elif [ ${general} != ${general%%f*} ]
    then
        abi=lp64f
    fi

    rm -f settings.mk
    echo "# Copyright (C) 2020 SiFive Inc" >> settings.mk
    echo "# SPDX-License-Identifier: Apache-2.0" >> settings.mk
    echo "" >> settings.mk
    echo "RISCV_ARCH = ${arch}" >> settings.mk
    echo "RISCV_ABI = ${abi}" >> settings.mk
    echo "RISCV_CMODEL = ${cmodel}" >> settings.mk
    echo "RISCV_SERIES = ${series}" >> settings.mk
    echo "" >> settings.mk
    echo "TARGET_TAGS = ${QUALIFIER}" >> settings.mk
}

generate_machine_properties() {
    rm -f ${FK_MACHINE}.properties
    echo "# SiFive Freedom Package Properties File" >> ${FK_MACHINE}.properties
    echo "PACKAGE_TYPE = freedom-kits" >> ${FK_MACHINE}.properties
    echo "PACKAGE_DESC_SEG = Freedom U SDK Machine" >> ${FK_MACHINE}.properties
    echo "PACKAGE_FIXED_ID = fusdk-machine" >> ${FK_MACHINE}.properties
    echo "PACKAGE_BUILD_ID = ${VERSION_ID}" >> ${FK_MACHINE}.properties
    echo "PACKAGE_MAJOR_ID = ${FK_DEVICE}" >> ${FK_MACHINE}.properties
    echo "PACKAGE_MINOR_ID = ${MACHINE}" >> ${FK_MACHINE}.properties
    echo "PACKAGE_QUAL_TAG = ${QUALIFIER}" >> ${FK_MACHINE}.properties
    echo "PACKAGE_VENDOR = SiFive" >> ${FK_MACHINE}.properties
    echo "PACKAGE_RIGHTS = sifive-v00" >> ${FK_MACHINE}.properties
}

do_sifive_wrapping() {
    # Setup defaults
    QUALIFIER=asic
    VERSION_ID=0000.00.0
    WRAPPINGS_DIR=${DEPLOY_DIR}/wrappings
    WRAPPINGS_TXT=${WRAPPINGS_DIR}/wrapping.txt
    OE_NAME=${IMAGE_BASENAME}-${MACHINE}

    # If there is a dts directory, then the machine is categorized as fpga based
    if [ -r ${DEPLOY_DIR_IMAGE}/dts ]
    then
        QUALIFIER=fpga
    fi
    # If there is a qemuboot.conf image file, then the machine is qemu based
    if [ -r ${DEPLOY_DIR_IMAGE}/${OE_NAME}.qemuboot.conf ]
    then
        QUALIFIER=qemu
    fi

    # Find the correct image version identifier, if one is available
    for osrel in ${BASE_WORKDIR}/all-oe-linux/os-release/*/image/usr/lib/os-release
    do
        if [ -r ${osrel} ]
        then
            while read oslin
            do
                case ${oslin} in
                (VERSION_ID=*)
                    VERSION_ID=${oslin#VERSION_ID=}
                    ;;
                (*)
                esac
            done < ${osrel}
        fi
    done

    # More defaults
    FK_NAME=${VERSION_ID}-${IMAGE_BASENAME}-${MACHINE}
    FK_IMAGE=fusdk-image-${FK_NAME}
    FK_ROOTFS=fusdk-rootfs-${FK_NAME}
    FK_SYSROOT=fusdk-sysroot-${FK_NAME}
    mkdir -p ${WRAPPINGS_DIR}
    cd ${WRAPPINGS_DIR}

    # Wrap up the image tarball
    if [ ${QUALIFIER} = qemu ]
    then
        FK_IMAGE_ZIPBALL=${FK_IMAGE}.ext4.xz
        rm -rf ${FK_IMAGE_ZIPBALL}
        xz --stdout -f -z -0 ${DEPLOY_DIR_IMAGE}/${OE_NAME}.ext4 > ${FK_IMAGE_ZIPBALL}
        sha512sum --tag ${FK_IMAGE_ZIPBALL} > ${FK_IMAGE}.ext4.sha512
    else
        FK_IMAGE_ZIPBALL=${FK_IMAGE}.wic.xz
        rm -rf ${FK_IMAGE_ZIPBALL}
        cp ${DEPLOY_DIR_IMAGE}/${OE_NAME}.wic.xz ${FK_IMAGE_ZIPBALL}
        sha512sum --tag ${FK_IMAGE_ZIPBALL} > ${FK_IMAGE}.wic.sha512
    fi

    rm -f ${FK_IMAGE}.properties
    echo "# SiFive Freedom Package Properties File" >> ${FK_IMAGE}.properties
    echo "PACKAGE_TYPE = freedom-kits" >> ${FK_IMAGE}.properties
    echo "PACKAGE_DESC_SEG = Freedom U SDK Image" >> ${FK_IMAGE}.properties
    echo "PACKAGE_FIXED_ID = fusdk-image" >> ${FK_IMAGE}.properties
    echo "PACKAGE_BUILD_ID = ${VERSION_ID}" >> ${FK_IMAGE}.properties
    echo "PACKAGE_MAJOR_ID = ${IMAGE_BASENAME}" >> ${FK_IMAGE}.properties
    echo "PACKAGE_MINOR_ID = ${MACHINE}" >> ${FK_IMAGE}.properties
    echo "PACKAGE_QUAL_TAG = ${QUALIFIER}" >> ${FK_IMAGE}.properties
    echo "PACKAGE_VENDOR = SiFive" >> ${FK_IMAGE}.properties
    echo "PACKAGE_RIGHTS = sifive-v00" >> ${FK_IMAGE}.properties

    # Wrap up the rootfs tarball
    FK_ROOTFS_TARBALL=${FK_ROOTFS}.tar.xz
    rm -f ${FK_ROOTFS_TARBALL}
    cp ${DEPLOY_DIR_IMAGE}/${OE_NAME}.tar.xz ${FK_ROOTFS_TARBALL}
    sha512sum --tag ${FK_ROOTFS_TARBALL} > ${FK_ROOTFS}.tar.sha512

    rm -f ${FK_ROOTFS}.properties
    echo "# SiFive Freedom Package Properties File" >> ${FK_ROOTFS}.properties
    echo "PACKAGE_TYPE = freedom-kits" >> ${FK_ROOTFS}.properties
    echo "PACKAGE_DESC_SEG = Freedom U SDK RootFS" >> ${FK_ROOTFS}.properties
    echo "PACKAGE_FIXED_ID = fusdk-rootfs" >> ${FK_ROOTFS}.properties
    echo "PACKAGE_BUILD_ID = ${VERSION_ID}" >> ${FK_ROOTFS}.properties
    echo "PACKAGE_MAJOR_ID = ${IMAGE_BASENAME}" >> ${FK_ROOTFS}.properties
    echo "PACKAGE_MINOR_ID = ${MACHINE}" >> ${FK_ROOTFS}.properties
    echo "PACKAGE_QUAL_TAG = ${QUALIFIER}" >> ${FK_ROOTFS}.properties
    echo "PACKAGE_VENDOR = SiFive" >> ${FK_ROOTFS}.properties
    echo "PACKAGE_RIGHTS = sifive-v00" >> ${FK_ROOTFS}.properties

    rm -rf ${FK_SYSROOT}
    mkdir -p ${FK_SYSROOT}
    cd ${FK_SYSROOT}

    # Unpacking rootfs tarball
    tar --warning=no-timestamp -xf ../${FK_ROOTFS_TARBALL}

    # Cleaning up top dirs that does not contain any include file or libraries
    rm -rf bin boot dev etc home media mnt proc run sbin share srv sys tmp var

    # Cleaning up usr subdirs that does not contain any include file or libraries
    cd usr
    rm -rf bin games libriscv64-oe-linux sbin src
    cd ..

    # Cleaning up broken links
    find . -xtype l -delete

    # This is needed in order to work on case insensitive file systems (windows and mac)
    # Cleaning up files/directories with same name but different case
    for dupl in $(find . | sort -f | uniq -i -d)
    do
        bbnote "Removing duplicate sysroot file with same name but different casing: ${dupl}"
        rm -rf ${dupl}
    done

    # Cleaning up broken links
    find . -xtype l -delete

    # Wrap up the sysroot tarball
    cd ..
    FK_SYSROOT_TAR=${FK_SYSROOT}.tar
    FK_SYSROOT_TARBALL=${FK_SYSROOT}.tar.xz
    rm -rf ${FK_SYSROOT_TAR} ${FK_SYSROOT_TARBALL}
    tar --dereference --hard-dereference --warning=no-timestamp -cf ${FK_SYSROOT_TAR} ${FK_SYSROOT}
    xz --stdout -f -z -0 ${FK_SYSROOT_TAR} > ${FK_SYSROOT_TARBALL}
    sha512sum --tag ${FK_SYSROOT_TARBALL} > ${FK_SYSROOT}.tar.sha512
    rm -rf ${FK_SYSROOT} ${FK_SYSROOT_TAR}

    rm -f ${FK_SYSROOT}.properties
    echo "# SiFive Freedom Package Properties File" >> ${FK_SYSROOT}.properties
    echo "PACKAGE_TYPE = freedom-kits" >> ${FK_SYSROOT}.properties
    echo "PACKAGE_DESC_SEG = Freedom U SDK SysRoot" >> ${FK_SYSROOT}.properties
    echo "PACKAGE_FIXED_ID = fusdk-sysroot" >> ${FK_SYSROOT}.properties
    echo "PACKAGE_BUILD_ID = ${VERSION_ID}" >> ${FK_SYSROOT}.properties
    echo "PACKAGE_MAJOR_ID = ${IMAGE_BASENAME}" >> ${FK_SYSROOT}.properties
    echo "PACKAGE_MINOR_ID = ${MACHINE}" >> ${FK_SYSROOT}.properties
    echo "PACKAGE_QUAL_TAG = ${QUALIFIER}" >> ${FK_SYSROOT}.properties
    echo "PACKAGE_VENDOR = SiFive" >> ${FK_SYSROOT}.properties
    echo "PACKAGE_RIGHTS = sifive-v00" >> ${FK_SYSROOT}.properties

    # Wrap up the machine tarball(s)
    if [ ${QUALIFIER} = fpga ]
    then
        for dts in ${DEPLOY_DIR_IMAGE}/dts/*.dts
        do
            FK_DEVICE=${dts%.dts}
            FK_DEVICE=${FK_DEVICE#${DEPLOY_DIR_IMAGE}/dts/}
            FK_NAME=${VERSION_ID}-${FK_DEVICE}-${MACHINE}
            FK_MACHINE=fusdk-machine-${FK_NAME}

            rm -rf ${FK_MACHINE}
            mkdir -p ${FK_MACHINE}
            cd ${FK_MACHINE}

            # Copy device tree dts file
            cp ${DEPLOY_DIR_IMAGE}/dtb/${FK_DEVICE}.dtb ./design.dtb
            cp ${DEPLOY_DIR_IMAGE}/dts/${FK_DEVICE}.dts ./design.dts

            generate_machine_settings

            cd ..
            FK_MACHINE_TARBALL=${FK_MACHINE}.tar.xz
            rm -rf ${FK_MACHINE_TARBALL}
            tar --dereference --hard-dereference --warning=no-timestamp -cJf ${FK_MACHINE_TARBALL} ${FK_MACHINE}
            sha512sum --tag ${FK_MACHINE_TARBALL} > ${FK_MACHINE}.tar.sha512
            rm -rf ${FK_MACHINE}

            generate_machine_properties
        done
    else
        FK_DEVICE=default
        FK_NAME=${VERSION_ID}-${MACHINE}
        FK_MACHINE=fusdk-machine-${FK_NAME}

        rm -rf ${FK_MACHINE}
        mkdir -p ${FK_MACHINE}
        cd ${FK_MACHINE}

        # Copy various machine files and generate device tree dts file
        if [ ${QUALIFIER} = qemu ]
        then
            # Copy various machine files
            cp ${DEPLOY_DIR_IMAGE}/${OE_NAME}.qemuboot.conf ./qemuboot.conf
            cp ${DEPLOY_DIR_IMAGE}/fw_dynamic.bin .
            cp ${DEPLOY_DIR_IMAGE}/fw_dynamic.elf .
            cp ${DEPLOY_DIR_IMAGE}/fw_jump.bin .
            cp ${DEPLOY_DIR_IMAGE}/fw_jump.elf .
            cp ${DEPLOY_DIR_IMAGE}/fw_payload.bin .
            cp ${DEPLOY_DIR_IMAGE}/fw_payload.elf .
            cp ${DEPLOY_DIR_IMAGE}/Image .
            cp ${DEPLOY_DIR_IMAGE}/u-boot.bin .
            cp ${DEPLOY_DIR_IMAGE}/u-boot.elf .
            cp ${DEPLOY_DIR_IMAGE}/uImage .

            eng="virt"
            cpu="rv64"
            smp="1"
            mem="256"
            while read cflin
            do
                case ${cflin} in
                (qb_machine*)
                    eng=${cflin#qb_machine = -machine }
                    ;;
                (qb_cpu*)
                    cpu=${cflin#qb_cpu = -cpu }
                    ;;
                (qb_smp*)
                    smp=${cflin#qb_smp = -smp }
                    ;;
                (qb_mem*)
                    mem=${cflin#qb_mem = -m }
                    ;;
                (*)
                esac
            done < ./qemuboot.conf
            FK_DEVICE=${eng}_${smp}

            for qemu in ${BASE_WORKDIR}/x86_64-linux/qemu-helper-native/*/recipe-sysroot-native/usr/bin/qemu-system-riscv64
            do
                ${qemu} -machine ${eng} -cpu ${cpu} -smp ${smp} -m ${mem} -machine dumpdtb=design.dtb
                dtc -q -I dtb -O dts -o ./design.dts ./design.dtb
            done
        else
            for dtb in ${DEPLOY_DIR_IMAGE}/*-${MACHINE}.dtb
            do
                cp ${dtb} ./design.dtb
                dtc -q -I dtb -O dts -o ./design.dts ./design.dtb
            done
        fi

        generate_machine_settings

        cd ..
        FK_MACHINE_WITHOUT_DEVICE=${FK_MACHINE}
        FK_NAME=${VERSION_ID}-${FK_DEVICE}-${MACHINE}
        FK_MACHINE=fusdk-machine-${FK_NAME}
        mv ${FK_MACHINE_WITHOUT_DEVICE} ${FK_MACHINE}
        FK_MACHINE_TARBALL=${FK_MACHINE}.tar.xz
        rm -rf ${FK_MACHINE_TARBALL}
        tar --dereference --hard-dereference --warning=no-timestamp -cJf ${FK_MACHINE_TARBALL} ${FK_MACHINE}
        sha512sum --tag ${FK_MACHINE_TARBALL} > ${FK_MACHINE}.tar.sha512
        rm -rf ${FK_MACHINE}

        generate_machine_properties
    fi
}

addtask do_sifive_wrapping before do_build after do_image_complete
