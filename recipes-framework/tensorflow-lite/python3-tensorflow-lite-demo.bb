DESCRIPTION = "A Sample of testing Tensorflow-lite with MNIST handwritten digits."
LICENSE = "CLOSED"

RDEPENDS:${PN} = "tensorflow-lite python3-numpy"

SRC_URI = "\
    file://demo/digit5.txt \
    file://demo/mnist.tflite \
    file://demo/mnist.py \
"

INHIBIT_DEFAULT_DEPS = "1"

S = "${WORKDIR}"

do_configure[noexec] = "1"

do_compile[noexec] = "1"

do_install() {
    install -d ${D}${datadir}/tensorflow/lite/examples/python
    install ${WORKDIR}/demo/digit5.txt ${D}${datadir}/tensorflow/lite/examples/python/digit5.txt
    install ${WORKDIR}/demo/mnist.py ${D}${datadir}/tensorflow/lite/examples/python/mnist.py
    install ${WORKDIR}/demo/mnist.tflite ${D}${datadir}/tensorflow/lite/examples/python/mnist.tflite
}

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

FILES:${PN} = "${datadir}/tensorflow/lite/examples/python/*"
