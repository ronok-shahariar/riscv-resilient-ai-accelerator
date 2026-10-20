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

    iverilog -g2012 \
        -s "$top" \
        -o "$executable" \
        "$rtl_source" \
        "$source"

    vvp "$executable" | tee "$logfile"

    if ! grep -Fq "$expected" "$logfile"; then
        echo "[FAIL] Expected PASS message not found: $name"
        exit 1
    fi

    echo "[PASS] $name"
}

# Build firmware before testing
./scripts/build_firmware.sh

# Test 1: Manually encoded RV32I instructions
run_test \
    "picorv32_baseline" \
    "tb_picorv32" \
    "simulation/testbench/tb_picorv32.v" \
    "PASS: PicoRV32 executed RV32I instructions correctly."

# Test 2: GCC-compiled bare-metal C firmware
run_test \
    "picorv32_firmware" \
    "tb_picorv32_firmware" \
    "simulation/testbench/tb_picorv32_firmware.v" \
    "PASS: Compiled C firmware executed successfully."

# Test 3: Directed, randomized, and overflow MAC verification
run_test \
    "int8_mac" \
    "tb_int8_mac" \
    "simulation/testbench/tb_int8_mac.v" \
    "[PASS] All INT8 MAC tests passed"

# Test 4: Exhaustive signed INT8 operand verification
run_test \
    "int8_mac_exhaustive" \
    "tb_int8_mac_exhaustive" \
    "simulation/testbench/tb_int8_mac_exhaustive.v" \
    "[PASS] Exhaustive INT8 MAC verification"

echo "===================================="
echo "[SUCCESS] All RTL and firmware tests passed"
echo "===================================="
