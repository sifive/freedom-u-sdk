LICENSE = "BSD-3-Clause"
COMPATIBLE_MACHINE = "unmatched|qemuriscv64|sifive-fpga"
GN_TARGET_ARCH_NAME:riscv64 = "riscv64"
GN_ARGS += 'use_custom_libcxx_for_host=true \
            ozone_platform="x11" \
            ozone_platform_headless=true \
            fatal_linker_warnings=false \
            enable_dav1d_decoder=false \
            enable_reading_list=false \
            enable_vr=false \
            supports_subzero=false \
            enable_openscreen=false \
            enable_jxl_decoder=false \
            use_thin_lto=false \
            use_lld=false'
PV = "104.0.5070.0"
SRC_URI[sha256sum] = "59895f6bd2dc385ef3c922161be69c2f304080e280b5f40a1385b9307f535321"
PATCHTOOL = "git"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:${THISDIR}/files/meta-chromium:"
PACKAGECONFIG:append := " custom-libcxx"
SRC_URI += "file://0001-linux-sysroot-script-to-create-riscv-sysroot-from-De.patch \
            file://0002-sandbox-add-riscv-arch-definition-and-define-syscall.patch \
            file://0003-sandbox-linux-pass-fPIE-to-compiler.patch \
            file://0004-skia-add-riscv64.patch \
            file://0005-base-allocator-partition_allocator-add-riscv64-suppo.patch \
            file://0006-base-process-add-riscv64-arch-definition.patch \
            file://0007-remoting-fix-missing-cstring-header.patch \
            file://0008-remoting-codec-fix-missing-cmath-header.patch \
            file://0009-components-update_client-add-riscv64-arch-definition.patch \
            file://0010-build-config-compiler-use_gold-linker-option.patch \
            file://0011-build-config-compiler-remove-flags-not-available-in-.patch \
            file://0012-build-config-add-atomic-build-flag.patch \
            file://0013-build-config-compiler-set-generic-riscv64-flags.patch \
            file://0014-chrome-common-remove-unrar-code.patch \
            file://0015-third_party-libaom-add-riscv-target.patch \
            file://0016-third_party-libvpx-add-riscv-target.patch \
            file://0017-third_party-crashpad-add-support-for-riscv.patch \
            file://0018-third_party-lzma_sdk-add-riscv-arch-definition.patch \
            file://0019-build-linux-sysroot-create-a-sysroot-for-riscv.patch \
            file://0020-workaround-for-files-not-found-in-sysroot.patch \
            file://0021-v8-settings.patch \
            file://0022-compiler-workaround.patch \
            file://0023-third-party-angle.patch \
            file://0024-third-party-dawn.patch \
            file://0025-third-party-ffmpeg.patch \
            file://0026-third-party-lss.patch \
            file://0027-third-party-pdfium.patch \
            file://0028-third-party-webrtc.patch \
            file://0029-third-party-libjxl-src.patch \
            file://0030-third-party-boringssl-src.patch \
            file://0031-third-party-breakpad-breakpad-header.patch \
            file://0032-third-party-breakpad-breakpad.patch \
            file://0033-third-party-highway-src.patch \
            file://0034-third-party-perfetto.patch \
            file://0035-third-party-skia.patch \
            file://sifive.patch"

setup_ffmpeg () {
    cd "${S}/third_party/ffmpeg"
    python3 ./chromium/scripts/build_ffmpeg.py linux riscv64
    python3 ./chromium/scripts/generate_gn.py
    ./chromium/scripts/copy_config.sh
    patch -R -p3 < "${WORKDIR}/0025-third-party-ffmpeg.patch"
}

do_patch[depends] += "clang-cross-riscv64:do_populate_sysroot \
                      glibc:do_populate_sysroot \
                      libgcc:do_populate_sysroot"
do_patch[postfuncs] += "setup_ffmpeg"

