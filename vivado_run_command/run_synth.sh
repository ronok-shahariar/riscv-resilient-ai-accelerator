#!/bin/bash
cd "$(dirname "$0")/.."
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BUILD_DIR="vivado_outputs/vivado_build_$TIMESTAMP"
mkdir -p "$BUILD_DIR"

echo "=== Starting Vivado Logical Synthesis ==="
vivado -nojournal -nolog -mode batch -source scripts/run_synth.tcl -tclargs "$BUILD_DIR" | tee "$BUILD_DIR/log_synth.txt"
echo "=== Synthesis Complete. Deliverables and log_synth.txt saved to $BUILD_DIR/ ==="
