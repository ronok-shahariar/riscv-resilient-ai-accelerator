# RISC-V-Based Fault-Resilient INT8 AI Accelerator

A research-oriented FPGA project integrating a **PicoRV32 RISC-V processor** with a custom **signed INT8 multiply-accumulate (MAC) accelerator**, using memory-mapped I/O (MMIO). Development proceeds incrementally from processor and firmware verification to accelerator integration, fault-resilience experiments, and FPGA implementation.

> **Current stage — Weeks 1–2 completed:** Processor-controlled INT8 MAC execution has been verified **in RTL simulation** and through automated GitHub Actions regression tests. Fault resilience, FPGA synthesis results, and on-board deployment have **not** yet been demonstrated.

## Start Here

- **[Architecture overview](architecture/architecture.md)** — concise SoC and verification diagrams, design decisions, and development roadmap.
- **[Week 1 engineering report](docs/weekly-reports/Week_01_RISCV_FPGA_Engineering_Report.md)** — PicoRV32 baseline, RV32I firmware execution, toolchain validation, and initial CI.
- **[Week 2 engineering report](docs/weekly-reports/Week_02_RISCV_INT8_Accelerator_Engineering_Report.md)** — INT8 MAC design, arithmetic and MMIO tests, CPU-controlled integration, debugging, and CI evidence.

## System Architecture

![PicoRV32 with simulation RAM, MMIO controller, and signed INT8 MAC](architecture/01-soc-overview.png)

The current **simulation testbench** connects the PicoRV32 RV32I CPU to **16 KB of instruction/data RAM**, a memory-mapped INT8 MAC controller at `0x80000000`, and a simulation-only result-reporting address at `0x10000000`. The MAC multiplies signed 8-bit operands, sign-extends the 16-bit product, and accumulates it in a signed 32-bit register; accumulator arithmetic wraps on overflow rather than saturating.

The MMIO controller provides activation, weight, control, status, and result registers. Bare-metal C firmware writes operands, issues `START`, polls the sticky `DONE` bit, and reads back the accumulator. The reusable MAC and peripheral are separate RTL modules; the current SoC address routing and RAM model live in a **simulation testbench**, not yet in a synthesizable top-level SoC.

For register addresses and diagrams, see the **[architecture overview](architecture/architecture.md)**.

## Verified Results

| Verification | Result | Scope |
|---|---|---|
| PicoRV32 baseline | Passed | RV32I instruction execution in simulation |
| PicoRV32 bare-metal firmware | Passed | GCC-compiled C firmware writes the expected MMIO value |
| INT8 MAC directed/randomized tests | **213 checks passed** | Signed arithmetic, boundaries, idle/clear controls, wraparound |
| INT8 MAC exhaustive test | **65,536 operand pairs passed** | Every signed INT8 activation/weight combination in the tested accumulation sequence |
| INT8 MAC MMIO peripheral | **16 checks passed** | Register operations, status, clear, and held-request behavior |
| PicoRV32 + INT8 MAC integration | Passed | Three firmware-issued MAC commands; accumulator **35 → 23 → 39** |

All **six regression suites** passed locally and in the GitHub Actions workflow through the Week 2 integration milestone. These results establish correctness of the **tested RTL simulation scenarios**; they are not FPGA throughput, power, timing-closure, or fault-tolerance measurements.

![RTL verification and CI pipeline](architecture/02-verification-pipeline.png)

## Reproduce the Tests

On Ubuntu with Icarus Verilog, Python 3, a compatible `riscv64-unknown-elf-gcc` cross-compiler, and RISC-V binutils installed:

```bash
# Run both firmware builds and all six RTL/firmware simulation suites
./scripts/run_tests.sh
```

The runner builds both the baseline and accelerator firmware, invokes Icarus Verilog (`iverilog`/`vvp`), and writes simulation logs under `simulation/build/`. The same command is executed by [GitHub Actions](.github/workflows/rtl-ci.yml) on Ubuntu 24.04.

## Target Platform and Tools

| Item | Selection / status |
|---|---|
| Target board | ALINX AX7203 — FPGA deployment planned |
| FPGA family | AMD/Xilinx Artix-7, XC7A200T family |
| Exact FPGA package and speed grade | **Not yet confirmed** |
| FPGA design tools | Vivado 2025.2, installation/device-family support checked |
| CPU | PicoRV32 (RV32I configuration) |
| Firmware | Freestanding C and RISC-V assembly, GNU cross-toolchain |
| Simulation | Icarus Verilog 12.0 (local baseline) |
| CI | GitHub Actions, Ubuntu 24.04 |

## Weekly Development Roadmap

| Week | Focus | Status | Documentation |
|---|---|---|---|
| **1** | PicoRV32 baseline, RV32I firmware, simulation, CI setup | **Completed** | [Week 1 report](docs/weekly-reports/Week_01_RISCV_FPGA_Engineering_Report.md) |
| **2** | Signed INT8 MAC, exhaustive verification, MMIO controller, CPU integration | **Completed** | [Week 2 report](docs/weekly-reports/Week_02_RISCV_INT8_Accelerator_Engineering_Report.md) |
| **3** | Define transient fault models; implement injection/detection/mitigation; quantify outcomes | Planned | Report pending |
| **4** | Synthesizable SoC integration, Vivado synthesis and timing/resource analysis; hardware evaluation if feasible | Planned | Report pending |

## Research Objectives

1. Integrate a RISC-V CPU with an INT8 accelerator.
2. Compare software and hardware execution cycles under a clearly defined benchmark.
3. Investigate transient bit-flip fault effects.
4. Evaluate low-overhead fault-detection and mitigation techniques.
5. Measure FPGA resource utilization and timing after synthesis and implementation.

## Repository Guide

| Location | Contents |
|---|---|
| [`architecture/`](architecture/) | High-level architecture overview and compact diagrams |
| [`rtl/cpu/`](rtl/cpu/) | PicoRV32 RTL and attribution/license files |
| [`rtl/accelerator/`](rtl/accelerator/) | INT8 MAC RTL and MMIO controller |
| [`firmware/src/`](firmware/src/) | Baseline bare-metal firmware and startup code |
| [`firmware/accelerator/`](firmware/accelerator/) | CPU-controlled accelerator firmware |
| [`simulation/testbench/`](simulation/testbench/) | Self-checking verification testbenches |
| [`scripts/`](scripts/) | Firmware build scripts and test runner |
| [`docs/weekly-reports/`](docs/weekly-reports/) | Detailed weekly engineering reports |
| [`screenshots/`](screenshots/) | Captured verification evidence |
| [`.github/workflows/`](.github/workflows/) | CI workflow |

## Limitations and Next Steps

The completed work provides a **simulation-verified baseline**, not yet a deployed, fault-resilient FPGA accelerator. In particular, there are no measured Artix-7 resource counts, timing closure results, on-board throughput figures, or fault-detection/mitigation performance metrics. The SoC testbench's RAM and address routing must also be migrated into synthesizable hardware before FPGA implementation.

Week 3 will define an explicit transient-fault model and measurable detection/mitigation criteria. Week 4 targets FPGA synthesis and evaluation, subject to confirming the exact AX7203 FPGA part and constraints.

## Licensing

The repository's overall license is to be determined. **PicoRV32 is a third-party core**; retain and follow its separately included license and attribution in `rtl/cpu/`.
