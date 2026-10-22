# RISC-V Resilient AI Accelerator SoC: Architecture & Verification Report

## 1. Executive Summary & Core Objective
This project implements a hardware-software co-designed **RISC-V SoC** integrated with a custom **INT8 Matrix-Multiply-Accumulate (MAC) coprocessor** and fault-tolerance safety mechanisms. Deployed on an **ALINX AX7203 FPGA board (AMD/Xilinx Artix-7 XC7A200T-2FBG484I)**[cite: 1], the system bridges general-purpose embedded computing with high-throughput, reliable edge AI acceleration.

---

## 2. Target Hardware Platform & Pin Mappings
- **Development Board**: ALINX AX7203[cite: 1]
- **FPGA Device**: AMD/Xilinx Artix-7 XC7A200T-2FBG484I[cite: 1]
- **System Clock**: 200 MHz Differential Oscillator (Pins R4/T4 via `IBUFDS`, `LVDS_25` IOSTANDARD)[cite: 1]
- **Reset Interface**: Active-Low Pushbutton (Pin T6, `LVCMOS15` IOSTANDARD)[cite: 1]
- **UART Interface**: Tx Line (Pin B13, `LVCMOS33` IOSTANDARD)[cite: 1]

---

## 3. Architecture Overview & System Topology
The system architecture revolves around a clean bus interconnect linking the processor core, unified memory, the custom INT8 MAC hardware accelerator, and peripheral interfaces.

![RISC-V SoC Block Diagram](./riscv_soc_block_diagram.jpeg)

### Architectural Breakdown:
1. **PicoRV32 CPU Core:** A lightweight 32-bit RISC-V soft-core processor (RV32IMC compliant)[cite: 1] that fetches instructions from BRAM, handles control flow, and coordinates data movement.
2. **16KB Dual-Port Block RAM (BRAM):** Mapped at base address `0x0000_0000`, serving as the unified memory space for instruction execution, global variables, and the runtime stack[cite: 1].
3. **MMIO Bus Intercept & Address Decoder:** Routes CPU read/write requests (`mem_valid`, `mem_ready`) based on target addresses, connecting to either the UART transmitter (`0x4000_0000`)[cite: 1] or the INT8 MAC coprocessor (`0x8000_0000`).
4. **INT8 MAC Coprocessor:** Houses dedicated signed 8-bit multiplier logic, activation/weight registers, a control interface, and a 32-bit accumulation register to accelerate tensor and matrix-multiply workloads.

---

## 4. Subsystem Architecture & Fault Resilience
- **CPU & Memory:** Optimized for small embedded footprints while providing enough headroom for bare-metal C applications[cite: 1].
- **Clocking & Resets:** Differential clock buffering (`IBUFDS`) scales the 200 MHz system clock down into stable single-ended logic domains[cite: 1].
- **Fault Resilience & ECC:** Implements dynamic numerical clamping logic and real-time error status flags to protect internal arithmetic pipelines against runtime bit-flips, radiation noise, or voltage spikes.

---

## 5. MMIO Register Map
The memory-mapped I/O structure exposes direct hardware control to software firmware:
- `0x4000_0000`: UART TX Data / Status Register[cite: 1]
- `0x8000_0000`: INT8 MAC Activation Register (Input vector A)
- `0x8000_0004`: INT8 MAC Weight Register (Input vector B)
- `0x8000_0008`: INT8 MAC Control Register (Trigger compute / clear accumulator)
- `0x8000_000C`: INT8 MAC Status Register (`DONE` / sticky fault flag)
- `0x8000_0010`: INT8 MAC Result Register (32-bit widened accumulator output)

---

## 6. Hardware Implementation & Resource Utilization
Post-implementation routing metrics on the Artix-7 FPGA confirm minimal hardware overhead:
- **Slice LUTs:** 12,450 / 134,600 (9.25%)[cite: 1]
- **Slice Registers:** 8,920 / 269,200 (3.31%)[cite: 1]
- **Block RAM (RAMB36E1):** 4 / 365 (1.10%)[cite: 1]
- **DSP48E1 Slices:** 16 / 740 (2.16%)[cite: 1]

---

## 7. Testing & Verification Procedure Flow
System correctness is established through a rigorous multi-tier validation pipeline spanning simulation, automated cloud checks, and physical hardware deployment.

![RISC-V SoC Testing and Verification Flowchart](./riscv_soc_verification_flow.jpeg)

### Verification Pipeline Stages:
1. **Phase 1: Local RTL Simulation & Regression:** Verilog source modules and testbenches (`tb_*.v`) are compiled and run via **Icarus Verilog** (`iverilog`/`vvp`). This validates baseline instruction execution, exhaustive signed 8-bit math checks ($65,536$ operand pairs), and fault-injection resilience.
2. **Phase 2: Automated CI/CD Pipeline:** GitHub Actions automatically provisions an Ubuntu runner on every code push, installs the RISC-V GNU Toolchain (`riscv64-unknown-elf-gcc`), compiles bare-metal C firmware, and executes the master test script (`./scripts/run_tests.sh`).
3. **Phase 3 & 4: FPGA Synthesis & Hardware-in-the-Loop (HIL):** Xilinx Vivado processes the RTL and timing constraints (`.xdc`) to generate the physical bitstream (`riscv_soc_top.bit`). The bitstream is flashed onto the ALINX AX7203 board, where live execution and UART telemetry are verified at 115200 baud.

---

## 8. Conclusion & Project Phase 1 Milestone
Phase 1 successfully establishes a fully verified, fault-resilient, and hardware-validated RISC-V AI accelerator baseline. With physical FPGA execution and automated CI pipelines fully operational, the architecture is primed for scaling into Phase 2 (multi-MAC systolic arrays and neural network inference layers).