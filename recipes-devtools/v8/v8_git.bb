DESCRIPTION = "Google’s open source high-performance JavaScript and WebAssembly engine."
HOMEPAGE = "https://v8.dev/"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=6611673a9587a522034a4be8f4df564c"

PR = "r0"
PV = "10.2.0+git${SRCPV}"

SRCREV = "9ba6aff285cd1e0682db217a2042c2e3187de5c1"
SRC_URI = "git://chromium.googlesource.com/v8/v8.git;protocol=https;branch=main \
           file://replace-toolchain.patch \
           file://parse-cpuinfo-for-features.patch \
           file://set-the-constant-of-VLEN-to-512.patch \
           file://0001-appfmws-1583-riscv64-Ensure-double-zero-is-set-before-canonicalizing-NaN.patch \
           file://0002-appfmws-1607-riscv64-Set-vl-with-proper-avl-for-target-with-vlen-other-than-128.patch \
           file://0003-appfmws-1610-riscv64-Always-output-vsetvli-to-avoid-mismatched-config-after-jump.patch \
           file://0004-appfmws-1631-riscv64-Fix-cctest-test-assembler-riscv64-RISCV_UTEST_FLOAT_WIDENING_vfwadd_vf.patch \
           file://0005-appfmws-1632-riscv64-Fix-cctest-test-assembler-riscv64-RISCV_UTEST_FLOAT_WIDENING_vfwmacc_vf.patch \
           file://0006-appfmws-1632-riscv64-sim-Fix-vector-widening-floating-point-fused-multiply-add-instructions.patch \
           file://0007-appfmws-1633-riscv64-Fix-cctest-test-assembler-riscv64-RISCV_UTEST_FLOAT_WIDENING_vfwredosum_vv.patch \
           file://0008-appfmws-1633-riscv64-sim-Correct-vfwredusum-and-vfwredosum-to-read-double-instead-of-float-from-vs1.patch \
           file://0009-appfmws-1634-riscv64-Fix-cctest-test-assembler-riscv64-RISCV_UTEST_swlwu.patch \
           file://0010-appfmws-1636-riscv64-Fix-cctest-test-run-wasm-simd-RunWasm_F64x2PromoteLowF32x4WithS128Load64Zero_liftoff.patch \
           file://0011-appfmws-1643-riscv64-Fix-mjsunit-wasm-huge-memory.patch \
           file://0012-appfmws-1657-riscv64-Fix-mjsunit-wasm-exceptions-api.patch \
           file://0013-appfmws-1664-riscv64-Fix-atomic-timeout.patch \
           file://0014-appfmws-1664-riscv64-use-not-equal-to-confirm-sc-whether-success-.patch \
           file://0015-appfmws-1666-riscv64-Fix-mjsunit-wasm-atomics64-stress.patch \
           file://0016-appfmws-1673-riscv64-Fix-cctest-test-assembler-riscv64-RISCV_UTEST_DOUBLE_vfadd_vv-for-different-VLEN.patch"

S = "${WORKDIR}/v8"

COMPATIBLE_HOST = "riscv64.*"
TOOLCHAIN = "clang"
OUTDIR = "out.gn/riscv64.release"

# Disable automatic update to ensure compatible depot_tools is kept.
export DEPOT_TOOLS_UPDATE = "0"

# Avoid polluting home directory on the automation infrastructure. By default
# the files in virtualenv are changed to read-only and got permission error
# while removing them. Remember to clean them when we're done.
export VPYTHON_VIRTUALENV_ROOT = "${WORKDIR}/.vpython-root"
export CIPD_CACHE_DIR = "${WORKDIR}/.vpython-cipd-cache"

PATH:prepend = "${STAGING_DATADIR_NATIVE}/depot_tools:"

do_fetch[depends] += "depot-tools-native:do_populate_sysroot"
do_fetch[depends] += "xz-native:do_populate_sysroot"

python () {
    # Get the download path from the git fetcher for V8 source URI.
    src_uri = d.getVar('SRC_URI').split()
    fetcher = bb.fetch2.Fetch(src_uri, d)
    d.setVar('fetchdir', fetcher.localpath(src_uri[0]))
}

python do_fetch() {
    src_uri = d.getVar('SRC_URI').split()
    fetcher = bb.fetch2.Fetch(src_uri, d)
    ud = fetcher.ud[src_uri[0]]
    if not ud.method.verify_donestamp(ud, d):
        fetchdir = d.getVar('fetchdir')
        v8dir = os.path.join(fetchdir, 'v8')
        if os.path.exists(fetchdir):
            bb.utils.prunedir(fetchdir)
        bb.utils.mkdirhier(fetchdir)
        # Fetch into the downloads folder to have it packaged into source mirror
        # tarball. Note |fetch v8| creates directories v8 and .cipd.
        try:
            bb.fetch2.runfetchcmd("fetch v8", d, workdir=fetchdir)
            bb.fetch2.runfetchcmd("git checkout %s" % d.getVar('SRCREV'), d, workdir=v8dir)
            bb.fetch2.runfetchcmd("gclient sync -D --force --reset", d, workdir=v8dir)
        finally:
            bb.fetch2.runfetchcmd("vpython -vpython-tool delete -all", d)
        ud.method.update_donestamp(ud, d)
}

python do_unpack() {
    if os.path.exists(d.getVar('S')):
        bb.utils.prunedir(d.getVar('S'))
    bb.fetch2.runfetchcmd("cp -rf . %s" % d.getVar('WORKDIR'), d, workdir=d.getVar('fetchdir'))
}

do_configure() {
    gn gen ${OUTDIR} --args='dcheck_always_on=false is_clang=true is_debug=false target_cpu="riscv64" use_custom_libcxx=false treat_warnings_as_errors=false clang_use_chrome_plugins=false target_sysroot="${STAGING_DIR_TARGET}" use_glib=false use_lld=false'
}

do_compile() {
    ninja -v ${PARALLEL_MAKE} -C ${OUTDIR}
}

do_install() {
    install -d ${D}${base_prefix}/opt/v8
    install -m 0755 ${S}/${OUTDIR}/d8 ${D}${base_prefix}/opt/v8
    install -m 0755 ${S}/${OUTDIR}/v8_hello_world ${D}${base_prefix}/opt/v8
    install -m 0644 ${S}/${OUTDIR}/snapshot_blob.bin ${D}${base_prefix}/opt/v8
    install -m 0644 ${S}/${OUTDIR}/icudtl.dat ${D}${base_prefix}/opt/v8
    install -m 0644 ${S}/LICENSE ${D}${base_prefix}/opt/v8
}

FILES:${PN} = "${base_prefix}/opt/*"
