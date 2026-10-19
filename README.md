# RISC-V-Based Fault-Resilient INT8 AI Accelerator

A research-oriented FPGA project integrating a PicoRV32
RISC-V CPU with a custom INT8 neural-network accelerator.

## Target Hardware

- Development Board: ALINX AX7203
- FPGA Family: AMD/Xilinx Artix-7 XC7A200T
- Exact FPGA Part: To be verified
- FPGA Toolchain: Vivado 2025.2
- RISC-V Compiler: GCC 13.2.0
- Simulator: Icarus Verilog 12.0

## Architecture

PicoRV32 (RV32I)
    |
    +-- Instruction/Data BRAM
    |
    +-- MMIO Interconnect
            |
            +-- INT8 Accelerator
                    |
                    +-- Weight/Activation Storage
                    +-- Fault Injection Unit
                    +-- INT8 Multiplier
                    +-- INT32 Accumulator
                    +-- Requantization and Clamping

## Research Objectives

1. Integrate a RISC-V CPU with an INT8 accelerator.
2. Compare software and hardware execution cycles.
3. Investigate transient bit-flip fault effects.
4. Evaluate low-overhead fault-mitigation techniques.
5. Measure FPGA resource utilization and timing.

## Current Status

Environment verified. Hardware development pending.

## License

To be determined.
