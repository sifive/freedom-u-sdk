DESCRIPTION = "A Sample of testing Tensorflow-lite with MNIST handwritten digits."
LICENSE = "CLOSED"

RDEPENDS:${PN} = "python3-tensorflow-lite python3-numpy"

SRC_URI = "\
    file://demo/digit5.txt \
    file://demo/mnist.tflite \
    file://demo/mnist.py \
"

INHIBIT_DEFAULT_DEPS = "1"

S = "${UNPACKDIR}"

do_configure[noexec] = "1"

do_compile[noexec] = "1"

do_install() {
    install -d ${D}${datadir}/tensorflow/lite/examples/python
    install ${UNPACKDIR}/demo/digit5.txt ${D}${datadir}/tensorflow/lite/examples/python/digit5.txt
    install ${UNPACKDIR}/demo/mnist.py ${D}${datadir}/tensorflow/lite/examples/python/mnist.py
    install ${UNPACKDIR}/demo/mnist.tflite ${D}${datadir}/tensorflow/lite/examples/python/mnist.tflite
}

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

FILES:${PN} = "${datadir}/tensorflow/lite/examples/python/*"
