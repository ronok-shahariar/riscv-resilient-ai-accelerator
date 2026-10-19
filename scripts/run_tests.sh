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
    local executable="$BUILD_DIR/${name}.vvp"
    local logfile="$BUILD_DIR/${name}.log"

    echo "===================================="
    echo "[TEST] $name"
    echo "===================================="

    iverilog -g2012 \
        -s "$top" \
        -o "$executable" \
        rtl/cpu/picorv32.v \
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

echo "===================================="
echo "[SUCCESS] All PicoRV32 tests passed"
echo "===================================="
