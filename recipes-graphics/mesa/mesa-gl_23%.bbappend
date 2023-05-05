VULKAN_DRIVERS:append:riscv64:class-target = ",amd"

# Add support for modern AMD GPU (e.g. RX550 / POLARIS)
PACKAGECONFIG:append:riscv64:class-target = " gallium-llvm vdpau"

# Add r600 drivers for AMD GPU
PACKAGECONFIG:append:riscv64:class-target = " r600"
