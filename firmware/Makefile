# Toolchain prefix pointing to Vivado Vitis bundled RISC-V GCC
CROSS_PREFIX = /home/ronok/Vivado2025.2/2025.2/Vitis/gnu/riscv/lin/bin/riscv64-unknown-elf-
CC = $(CROSS_PREFIX)gcc
OBJCOPY = $(CROSS_PREFIX)objcopy

# Compilation flags targeting RV32I freestanding environment
CFLAGS = -O0 -mabi=ilp32 -march=rv32i -ffreestanding -nostdlib
LDFLAGS = -Wl,-Bstatic,-T,linker/picorv32.ld,--strip-debug,--build-id=none

# Default target builds the hex file required for BRAM
all: build/firmware.hex

build/start.o: src/start.S
	@mkdir -p build
	$(CC) $(CFLAGS) -c $< -o $@

build/main.o: src/main.c
	@mkdir -p build
	$(CC) $(CFLAGS) -c $< -o $@

build/firmware.elf: build/start.o build/main.o linker/picorv32.ld
	@mkdir -p build
	$(CC) $(CFLAGS) $(LDFLAGS) build/start.o build/main.o -o $@

build/firmware.bin: build/firmware.elf
	@mkdir -p build
	$(OBJCOPY) -O binary $< $@

build/firmware.hex: build/firmware.bin
	@mkdir -p build
	python3 -c "b = open('build/firmware.bin', 'rb').read(); b += b'\x00' * (-len(b) % 4); open('build/firmware.hex', 'w').writelines([f'{int.from_bytes(b[i:i+4], \"little\"):08x}\n' for i in range(0, len(b), 4)])"

clean:
	rm -rf build/*

.PHONY: all clean
