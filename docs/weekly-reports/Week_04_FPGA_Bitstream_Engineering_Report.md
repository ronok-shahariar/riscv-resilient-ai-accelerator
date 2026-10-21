# Week 04: FPGA Synthesis, Constraints Engineering, and Bitstream Generation for RISC-V SoC

## 1. Executive Summary & Architecture Overview

This report details the complete physical synthesis, timing constraints design, and bitstream generation pipeline for the RISC-V SoC targeted at the [ALINX AX7203](https://www.alinx.com/) development board containing the AMD/Xilinx Artix-7 XC7A200T-2FBG484I FPGA. The system integrates a 32-bit PicoRV32 processor core, 16KB of dual-port Block RAM (BRAM), an 8-bit integer matrix-multiply accelerator (int8_mac), and differential clock management modules.

### 1.1 System Component Summary

| Module | Function / Description | Target Subsystem |
|---|---|---|
| PicoRV32 Core | RV32IMC ISA compliance, bus interface | Main Processing Unit |
| 16KB Dual-Port BRAM | Unified instruction and data memory | On-Chip Memory System |
| int8_mac Accelerator | 8-bit integer multiply-accumulate array | AI Coprocessor |
| IBUFDS Primitive | 200 MHz differential to single-ended buffer | Clock & Reset Management |

## 2. Clocking and I/O Constraints Engineering

The ALINX AX7203 board utilizes a 200 MHz differential system clock oscillator connected to pins R4 (positive) and T4 (negative). To properly instantiate this input in Vivado, an [IBUFDS primitive](https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries) is required alongside LVDS_25 I/O standard definitions in the Xilinx Design Constraints (XDC) file.

### 2.1 Target Board Specification & Pin Out

| Signal Name | FPGA Pin | I/O Standard | Description |
|---|---|---|---|
| sys_clk_p | R4 | LVDS_25 | 200 MHz System Clock (Positive) |
| sys_clk_n | T4 | LVDS_25 | 200 MHz System Clock (Negative) |
| sys_rst_n | T6 | LVCMOS15 | Active-Low Reset Pushbutton |
| uart_tx | B13 | LVCMOS33 | UART Transmitter Line |

### 2.2 Primary Timing Constraints (constraints.xdc)

```
# System Clock: 200 MHz Differential (Period = 5.000 ns)
create_clock -period 5.000 -name sys_clk_pin [get_ports sys_clk_p]
set_property PACKAGE_PIN R4 [get_ports sys_clk_p]
set_property PACKAGE_PIN T4 [get_ports sys_clk_n]
set_property IOSTANDARD LVDS_25 [get_ports sys_clk_p]
set_property IOSTANDARD LVDS_25 [get_ports sys_clk_n]

# Active Low Reset Input
set_property PACKAGE_PIN T6 [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS15 [get_ports sys_rst_n]
```

## 3. Automated Synthesis & Bitstream Workflows

To support non-interactive execution and reproducible continuous integration, the build process is managed via non-GUI Vivado Tcl scripts. All synthesis, place, route, and bitstream artifacts are automatically organized under timestamped directories within `vivado_outputs/`.

### 3.1 Shell Execution Commands

The build suite provides two distinct automated scripts based on execution requirements:

```bash
# 1. Run Logical Check and Synthesis (Fast verification & utilization report)
./vivado_run_command/run_synth.sh

# 2. Complete Build Pipeline (Synthesis, Place & Route, Bitstream Generation)
./vivado_run_command/run_hardware.sh
```

### 3.2 Output Directory Structure

Upon completion, the build script generates structured outputs under the target folder:

```
vivado_outputs/
└── build_YYYYMMDD_HHMMSS/
    ├── logs/
    │   ├── synthesis.log
    │   └── implementation.log
    ├── reports/
    │   ├── utilization_synth.rpt
    │   ├── timing_summary.rpt
    │   └── power_analysis.rpt
    └── bitstream/
        └── riscv_soc_top.bit
```

## 4. FPGA Resource Utilization Summary

Following successful implementation for the XC7A200T-2FBG484I FPGA, post-route resource usage reports confirm total hardware overhead fits well within device thresholds:

| Resource Type | Used | Available | Utilization % |
|---|---|---|---|
| Slice LUTs | 12,450 | 134,600 | 9.25% |
| Slice Registers | 8,920 | 269,200 | 3.31% |
| Block RAM (RAMB36E1) | 4 | 365 | 1.10% |
| DSP48E1 Slices | 16 | 740 | 2.16% |



## 6. Visual Evidence & Build Verification

### Figure 1: Repository Structure & Clean Workspace
![Workspace Structure](../../screenshots/week04/workspace_tree.png)

### Figure 2: Successful Bitstream Generation Terminal Output
![Bitgen Success](../../screenshots/week04/bitgen_success.png)

### Figure 3: FPGA Resource Utilization Summary
![Utilization Report](../../screenshots/week04/synth_utilization.png)