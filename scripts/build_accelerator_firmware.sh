#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

BUILD_DIR="firmware/accelerator/build"
mkdir -p "$BUILD_DIR"

echo "========================================"
echo "WEEK 2: RISC-V ACCELERATOR FIRMWARE BUILD"
echo "========================================"

echo "[BUILD] Compiling RV32I accelerator firmware"

# Use CROSS_PREFIX environment variable if set, otherwise default to container's toolchain
CROSS_PREFIX="${CROSS_PREFIX:-riscv32-unknown-elf-}"

"${CROSS_PREFIX}gcc" \
  -march=rv32i \
  -mabi=ilp32 \
  -O2 \
  -ffreestanding \
  -fno-builtin \
  -fno-pic \
  -msmall-data-limit=0 \
  -mno-relax \
  -nostdlib \
  -nostartfiles \
  -Wl,--no-relax \
  -Wl,--build-id=none \
  -T firmware/linker/picorv32.ld \
  firmware/src/start.S \
  firmware/accelerator/main.c \
  -o "$BUILD_DIR/accelerator.elf"

echo "[BUILD] Generating firmware binary"

"${CROSS_PREFIX}objcopy" \
  -O binary \
  "$BUILD_DIR/accelerator.elf" \
  "$BUILD_DIR/accelerator.bin"

echo "[BUILD] Generating 32-bit HEX image"

python3 - <<'PY'
from pathlib import Path

source = Path("firmware/accelerator/build/accelerator.bin")
target = Path("firmware/accelerator/build/accelerator.hex")

data = source.read_bytes()

if len(data) % 4:
    data += bytes(4 - len(data) % 4)

with target.open("w") as file:
    for offset in range(0, len(data), 4):
        word = int.from_bytes(data[offset:offset + 4], "little")
        file.write(f"{word:08x}\n")

print(f"[BUILD] Generated {len(data) // 4} words")
PY

echo "[PASS] Accelerator firmware build completed"
echo "========================================"