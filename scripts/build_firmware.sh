#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p firmware/build

echo "[BUILD] Compiling RV32I firmware"

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
  firmware/src/main.c \
  -o firmware/build/firmware.elf

echo "[BUILD] Generating firmware binary"

"${CROSS_PREFIX}objcopy" \
  -O binary \
  firmware/build/firmware.elf \
  firmware/build/firmware.bin

echo "[BUILD] Generating 32-bit HEX image"

python3 - <<'PY'
from pathlib import Path

source = Path("firmware/build/firmware.bin")
target = Path("firmware/build/firmware.hex")

data = source.read_bytes()

if len(data) % 4:
    data += bytes(4 - len(data) % 4)

with target.open("w") as file:
    for offset in range(0, len(data), 4):
        word = int.from_bytes(
            data[offset:offset + 4], "little"
        )
        file.write(f"{word:08x}\n")

print(f"[BUILD] Generated {len(data)//4} words")
PY

echo "[PASS] Firmware build completed"