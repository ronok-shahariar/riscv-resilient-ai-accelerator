CROSS_PREFIX ?= riscv64-unknown-elf-

CC = $(CROSS_PREFIX)gcc
OBJCOPY = $(CROSS_PREFIX)objcopy

CFLAGS = -O0 -mabi=ilp32 -march=rv32i -ffreestanding -nostdlib -nostartfiles -Wl,--build-id=none

all: build/firmware.bin build/firmware.hex

build/start.o: src/start.S
	mkdir -p build
	$(CC) $(CFLAGS) -c $< -o $@

build/main.o: src/main.c
	mkdir -p build
	$(CC) $(CFLAGS) -c $< -o $@

build/firmware.elf: build/start.o build/main.o linker/picorv32.ld
	$(CC) $(CFLAGS) -T linker/picorv32.ld build/start.o build/main.o -o $@

build/firmware.bin: build/firmware.elf
	$(OBJCOPY) -O binary $< $@

build/firmware.hex: build/firmware.bin
	python3 -c "from pathlib import Path; b = Path('build/firmware.bin').read_bytes(); b += b'\x00' * (-len(b) % 4); Path('build/firmware.hex').write_text(''.join(f'{int.from_bytes(b[i:i+4], \"little\"):08x}\n' for i in range(0, len(b), 4)))"

clean:
	rm -rf build/*