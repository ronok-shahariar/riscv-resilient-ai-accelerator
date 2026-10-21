#!/bin/bash
cd "$(dirname "$0")/.."
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BUILD_DIR="vivado_outputs/vivado_hw_build_$TIMESTAMP"
mkdir -p "$BUILD_DIR"

echo "=== Starting Vivado Hardware Implementation & Bitstream Generation ==="
vivado -nojournal -nolog -mode batch -source scripts/run_hardware.tcl -tclargs "$BUILD_DIR" | tee "$BUILD_DIR/log_hw.txt"
echo "=== Hardware Bitstream Complete. Deliverables and log_hw.txt saved to $BUILD_DIR/ ==="
