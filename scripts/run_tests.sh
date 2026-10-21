#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

BUILD_DIR="simulation/build"
mkdir -p "$BUILD_DIR"

run_test() {
    local name="$1"
    local top="$2"
    local source="$3"
    local expected="$4"
    local rtl_source="rtl/cpu/picorv32.v"

    if [[ "$name" == int8_mac* ]]; then
        rtl_source="rtl/accelerator/int8_mac.v"
    fi

    local executable="$BUILD_DIR/${name}.vvp"
    local logfile="$BUILD_DIR/${name}.log"

    echo "===================================="
    echo "[TEST] $name"
    echo "===================================="

    iverilog -g2012         -s "$top"         -o "$executable"         "$rtl_source"         "$source"

    vvp "$executable" | tee "$logfile"

    if ! grep -Fq "$expected" "$logfile"; then
        echo "[FAIL] Expected PASS message not found: $name"
        exit 1
    fi

    echo "[PASS] $name"
}

# Build legacy firmware before testing
./scripts/build_firmware.sh

# Test 1: Manually encoded RV32I instructions
run_test     "picorv32_baseline"     "tb_picorv32"     "simulation/testbench/tb_picorv32.v"     "PASS: PicoRV32 executed RV32I instructions correctly."

# Test 2: GCC-compiled bare-metal C firmware
run_test     "picorv32_firmware"     "tb_picorv32_firmware"     "simulation/testbench/tb_picorv32_firmware.v"     "PASS: Compiled C firmware executed successfully."

# Test 3: Directed, randomized, and overflow MAC verification
run_test     "int8_mac"     "tb_int8_mac"     "simulation/testbench/tb_int8_mac.v"     "[PASS] All INT8 MAC tests passed"

# Test 4: Exhaustive signed INT8 operand verification
run_test     "int8_mac_exhaustive"     "tb_int8_mac_exhaustive"     "simulation/testbench/tb_int8_mac_exhaustive.v"     "[PASS] Exhaustive INT8 MAC verification"

# Test 5: Fault injection and clamping resilience verification
run_test     "int8_mac_fault"     "tb_int8_mac_fault"     "simulation/testbench/tb_int8_mac_fault.v"     "[PASS] All Fault Resilience checks passed"

# Test 6: INT8 MAC MMIO peripheral
echo "===================================="
echo "[TEST] int8_mac_mmio"
echo "===================================="

iverilog -g2012 -Wall     -s tb_int8_mac_mmio     -o "$BUILD_DIR/int8_mac_mmio.vvp"     rtl/accelerator/int8_mac.v     rtl/accelerator/int8_mac_mmio.v     simulation/testbench/tb_int8_mac_mmio.v

vvp "$BUILD_DIR/int8_mac_mmio.vvp" | tee "$BUILD_DIR/int8_mac_mmio.log"

grep -Fq "[PASS] All MMIO verification tests passed" "$BUILD_DIR/int8_mac_mmio.log"
grep -Fq "Checks completed: 16" "$BUILD_DIR/int8_mac_mmio.log"

echo "[PASS] int8_mac_mmio"

# Test 7: End-to-end PicoRV32 + INT8 MAC SoC integration
echo "===================================="
echo "[TEST] picorv32_accelerator"
echo "===================================="

./scripts/build_accelerator_firmware.sh

iverilog -g2012 -Wall     -s tb_picorv32_accelerator     -o "$BUILD_DIR/picorv32_accelerator.vvp"     rtl/cpu/picorv32.v     rtl/accelerator/int8_mac.v     rtl/accelerator/int8_mac_mmio.v     simulation/testbench/tb_picorv32_accelerator.v

vvp "$BUILD_DIR/picorv32_accelerator.vvp" | tee "$BUILD_DIR/picorv32_accelerator.log"

grep -Fq "[PASS] PicoRV32 controlled INT8 MAC" "$BUILD_DIR/picorv32_accelerator.log"
grep -Fq "[PASS] Three MAC commands completed" "$BUILD_DIR/picorv32_accelerator.log"
grep -Fq "[PASS] Final accumulator = 39" "$BUILD_DIR/picorv32_accelerator.log"

if [[ $(grep -c "^\[MAC\] START command" "$BUILD_DIR/picorv32_accelerator.log") -ne 3 ]]; then
    echo "[FAIL] Expected exactly three START commands"
    exit 1
fi

echo "[PASS] picorv32_accelerator"

echo "===================================="
echo "[SUCCESS] All RTL and firmware tests passed"
echo "===================================="
