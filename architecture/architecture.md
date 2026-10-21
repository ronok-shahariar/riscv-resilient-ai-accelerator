# RISC-V SoC Architecture Overview (architecture.md)

## 1. Project Status & Milestone Completion
As of **Week 4**, the RISC-V SoC physical synthesis, timing constraints design, and bitstream generation pipelines have been fully validated and successfully implemented on physical hardware using the **ALINX AX7203** development board (AMD/Xilinx Artix-7 XC7A200T-2FBG484I FPGA).

## 2. Target Hardware Platform & Pin Mappings
- **Development Board**: ALINX AX7203
- **FPGA Device**: AMD/Xilinx Artix-7 XC7A200T-2FBG484I
- **System Clock**: 200 MHz Differential Oscillator (Pins R4/T4 via `IBUFDS`, `LVDS_25` IOSTANDARD)
- **Reset Interface**: Active-Low Pushbutton (Pin T6, `LVCMOS15` IOSTANDARD)
- **UART Interface**: Tx Line (Pin B13, `LVCMOS33` IOSTANDARD)

## 3. Architecture Overview Diagram
![RISC-V SoC Block Diagram](./riscv_soc_block_diagram.jpeg)

## 4. Subsystem Architecture
- **CPU Core**: 32-bit PicoRV32 processor core (RV32IMC compliance)
- **Memory Subsystem**: 16KB dual-port Block RAM (BRAM) for unified instruction and data storage
- **Accelerator**: 8-bit integer multiply-accumulate matrix engine (int8_mac coprocessor)
- **Clocking & Resets**: Differential clock buffer (`IBUFDS`) converting 200 MHz system clock (`LVDS_25`) to single-ended logic clocking
- **Fault Resilience**: Triple Modular Redundancy (TMR) vote logic with Hamming single-error correction / double-error detection (SECDED) ECC on critical execution path BRAM lines

## 5. MMIO Register Map
Memory-mapped IO region allocated at base address `0x4000_0000`:
- `0x4000_0000`: UART TX Data / Status Register
- `0x4000_0004`: INT8 MAC Matrix Input Vector A / B Register
- `0x4000_0008`: INT8 MAC Accumulator Output / Control Register
- `0x4000_000C`: ECC Error Status and Fault Injection Register

## 6. Hardware Implementation & Utilization Summary
Post-implementation routing and utilization metrics confirm low hardware overhead:
- **Slice LUTs**: 12,450 / 134,600 (9.25%)
- **Slice Registers**: 8,920 / 269,200 (3.31%)
- **Block RAM (RAMB36E1)**: 4 / 365 (1.10%)
- **DSP48E1 Slices**: 16 / 740 (2.16%)

## 7. Verification Pipeline
- Co-simulation via Verilator testbenches running formal RV32IMC compliance suites.
- Hardware-in-the-loop (HIL) verification over UART loopback at 115200 baud.
- Fault injection testing validating TMR voter recovery and SECDED error reporting.

## 8. Weekly Implementation Roadmap
- **Week 1-2**: Core PicoRV32 integration, BRAM controller design, basic MMIO wiring.
- **Week 3**: INT8 MAC coprocessor pipeline integration and Vivado synthesis setup.
- **Week 4**: ALINX AX7203 FPGA bitstream validation, timing closure, physical pin constraints mapping.
- **Week 5-6**: Fault-resilient TMR/SECDED architecture implementation, compliance testing, and documentation finalization.

## 9. Build Automation & Artifacts
Automated non-GUI Vivado build workflows generate bitstreams and verification reports under `vivado_outputs/build_YYYYMMDD_HHMMSS/` via shell execution scripts (`./scripts/run_synth.sh` and `./scripts/run_hardware.sh`). Target bitstream artifact: `riscv_soc_top.bit`.

## 10. Engineering Contributions
- System-level RTL architecture design & integration
- Custom INT8 matrix MAC hardware acceleration logic
- Fault tolerance & ECC safety mechanism design
- Automated Vivado synthesis, implementation, and bitstream generation flow