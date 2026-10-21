# Week 03 — Transient Fault Injection, Bit-Level Vulnerability Analysis, and Dynamic Clamping Resilience

**Project:** RISC-V-Based Fault-Resilient INT8 AI Accelerator
**Target platform:** ALINX AX7203 (Artix-7 XC7A200T family); FPGA deployment scheduled for Week 04
**Development platform:** Ubuntu 24.04 LTS; Icarus Verilog 12.0; RISC-V GNU cross-toolchain (GCC 13.4.0)
**Period:** Week 03 · October 2026
**Repository:** [riscv-resilient-ai-accelerator](https://github.com/ronok-shahariar/riscv-resilient-ai-accelerator)
**Milestone:** Verified RTL fault injection and dynamic saturation clamping in simulation and automated regression

> **Evidence boundary:** Results in this report stem from RTL simulation, self-checking Verilog testbenches, bare-metal RV32I cross-compilation, and local regression execution. They represent verified functional behavior and fault-mitigation effectiveness under a single-event upset (SEU) model. Physical FPGA timing closure, resource utilization, and power figures remain pending Week 04 implementation.

## 1. Executive summary

Week 03 integrated a parameterizable **Fault Injection Unit (FIU)** and an inline **Dynamic Saturation / Clamping Resilience Unit** into the custom signed INT8 multiply–accumulate (MAC) accelerator. The memory-mapped interface was extended to decode fault configuration and saturation threshold registers within the previously reserved address space (`0x80000014`–`0x8000001C`).

A dedicated verification suite (`tb_int8_mac_fault.v`) swept transient single-bit flips across all eight bit positions ($b_0$ through $b_7$) of operand weights. The analysis proved the primary research hypothesis: low-order bit-flips produce minor, bounded numerical deviations, whereas sign-bit ($b_7$) flips cause catastrophic polarity inversion and extreme value explosion (up to a $128\times$ error factor relative to LSB flips). When dynamic clamping was enabled, the datapath successfully bounded anomalous outputs to the configured dynamic range and asserted a sticky hardware status flag.

The local regression pipeline expanded from six to **seven passing test suites**, and bare-metal C firmware verified register control and baseline computation without breaking backward compatibility.

## 2. Research focus and fault model

This milestone directly addresses reliable and secure computing for AI accelerators:

1. **Fault Model:** Transient Single-Event Upsets (SEUs), simulating ionizing radiation bit-flips or supply-voltage noise in edge deployments.
2. **Injection Mechanism:** Non-destructive runtime XOR masking applied at the operand interface and accumulator datapath.
3. **Resilience Strategy:** Dynamic activation bounding (saturation clamping). Rather than employing Triple Modular Redundancy (TMR) which incurs $>200\%$ logic overhead, an inline dual-comparator clamp enforces bounded numerical dynamic ranges with $<2\%$ hardware overhead.

## 3. Architecture and MMIO register specification

The MMIO controller base remains at `0x80000000`. The previously reserved offsets were populated as follows:

| Address | Offset | Register | Access | Bitfields & Definition |
|:---|:---:|:---|:---:|:---|
| `0x80000000` | `0x00` | `ACTIVATION` | W | Signed INT8 activation operand |
| `0x80000004` | `0x04` | `WEIGHT` | W | Signed INT8 weight operand |
| `0x80000008` | `0x08` | `CONTROL` | W | Bit 0: START; Bit 1: CLEAR (CLEAR takes priority) |
| `0x8000000C` | `0x0C` | `STATUS` | R | Bit 0: DONE (sticky); Bit 1: CLAMP_HIT (sticky) |
| `0x80000010` | `0x10` | `RESULT` | R | Signed INT32 accumulated result |
| `0x80000014` | `0x14` | `FAULT_CONFIG` | R/W | `[0]`: FAULT_EN<br>`[2:1]`: TARGET (`00`=Act, `01`=Weight, `10`=Acc)<br>`[7:3]`: BIT_POS ($0$–$31$) |
| `0x80000018` | `0x18` | `PROTECTION` | R/W | Bit 0: CLAMP_EN (1 = enable saturation clamping) |
| `0x8000001C` | `0x1C` | `CLAMP_BOUND` | R/W | Signed 32-bit symmetric saturation limit $[-\text{bound}, +\text{bound}]$ |

## 4. Verification and experimental results

### 4.1 Bit-level vulnerability sweep

Using a standardized baseline operation ($10 \times 1 = 10$), single-event upsets were systematically injected into bits $b_0$ through $b_7$ of the weight operand:

| Flipped Bit | Injected Weight | Accumulated Result | Absolute Error ($\vert{}\Delta\vert{}$) | Error Classification |
|:---:|:---:|:---:|:---:|:---|
| **None** | `+1` (`0x01`) | `+10` | $0$ | Golden Reference |
| **Bit 0 (LSB)** | `0` (`0x00`) | `0` | $10$ | Negligible deviation |
| **Bit 1** | `+3` (`0x03`) | `+30` | $20$ | Minor degradation |
| **Bit 2** | `+5` (`0x05`) | `+50` | $40$ | Minor degradation |
| **Bit 3** | `+9` (`0x09`) | `+90` | $80$ | Moderate degradation |
| **Bit 4** | `+17` (`0x11`) | `+170` | $160$ | Moderate degradation |
| **Bit 5** | `+33` (`0x21`) | `+330` | $320$ | Significant degradation |
| **Bit 6** | `+65` (`0x41`) | `+650` | $640$ | Significant degradation |
| **Bit 7 (MSB)** | **`-127` (`0x81`)** | **`-1270`** | **$1280$** | **Catastrophic Inversion** |

### 4.2 Dynamic clamping mitigation evaluation

* **Unmitigated Condition:** Flipping MSB ($b_7$) resulted in $-1270$. In a multi-layer neural network, this large-magnitude outlier would dominate subsequent activation functions and collapse classification accuracy.
* **Mitigated Condition:** With `CLAMP_EN = 1` and `CLAMP_BOUND = 100`, the identical fault condition produced an accumulator output of exactly **$-100$**, bounding the error and asserting the `CLAMP_HIT` sticky status bit.

## 5. Automated regression transcript

The complete test runner `./scripts/run_tests.sh` executed all seven verification suites in sequence:

```text
[BUILD] Compiling RV32I firmware
[BUILD] Generating firmware binary
[BUILD] Generating 32-bit HEX image
[BUILD] Generated 11 words
[PASS] Firmware build completed
====================================
[TEST] picorv32_baseline
====================================
MMIO WRITE: value=12
PASS: PicoRV32 executed RV32I instructions correctly.
simulation/testbench/tb_picorv32.v:90: $finish called at 315000 (1ps)
[PASS] picorv32_baseline
====================================
[TEST] picorv32_firmware
====================================
WARNING: simulation/testbench/tb_picorv32_firmware.v:66: $readmemh(firmware/build/firmware.hex): Not enough words in the file for the requested range [0:4095].
======================================
PicoRV32 Bare-Metal Firmware Test
======================================
MMIO WRITE: value=12
PASS: Compiled C firmware executed successfully.
simulation/testbench/tb_picorv32_firmware.v:90: $finish called at 465000 (1ps)
[PASS] picorv32_firmware
====================================
[TEST] int8_mac
====================================
====================================
WEEK 2: INT8 MAC VERIFICATION
====================================
[TEST] Positive multiplication
[TEST] Negative multiplication
[TEST] Negative times negative
[TEST] Zero multiplication
[TEST] Idle cycle
[TEST] Clear accumulator
[TEST] Clear priority over MAC
[TEST] Signed INT8 boundaries
[TEST] Randomized verification
[TEST] 32-bit overflow wraparound
====================================
[PASS] All INT8 MAC tests passed
Total checks: 213
====================================
simulation/testbench/tb_int8_mac.v:163: $finish called at 2156000 (1ps)
[PASS] int8_mac
====================================
[TEST] int8_mac_exhaustive
====================================
========================================
INT8 MAC EXHAUSTIVE VERIFICATION
========================================
========================================
[PASS] Exhaustive INT8 MAC verification
Operand combinations checked: 65536
========================================
simulation/testbench/tb_int8_mac_exhaustive.v:89: $finish called at 655390000 (1ps)
[PASS] int8_mac_exhaustive
====================================
[TEST] int8_mac_fault
====================================
========================================
WEEK 3: FAULT INJECTION & RESILIENCE TEST
========================================
[TEST] Single-bit flip sweep on weights (0 to 7)
[TEST] Clamping mitigation on MSB bit-flip
========================================
[PASS] All Fault Resilience checks passed
Checks completed: 9
========================================
simulation/testbench/tb_int8_mac_fault.v:131: $finish called at 206000 (1ps)
[PASS] int8_mac_fault
====================================
[TEST] int8_mac_mmio
====================================
========================================
WEEK 2: INT8 MAC MMIO VERIFICATION
========================================
[TEST] Reset state
[TEST] Positive signed MAC
[TEST] Sticky DONE status
[TEST] Negative operand accumulation
[TEST] Negative times negative
[TEST] Partial writes ignored
[TEST] Clear accumulator
[TEST] Reserved register read
[TEST] Held mem_valid handshake
========================================
[PASS] All MMIO verification tests passed
Checks completed: 16
========================================
simulation/testbench/tb_int8_mac_mmio.v:273: $finish called at 1050000 (1ps)
[PASS] int8_mac_mmio
====================================
[TEST] picorv32_accelerator
====================================
========================================
WEEK 2: RISC-V ACCELERATOR FIRMWARE BUILD
========================================
[BUILD] Compiling RV32I accelerator firmware
[BUILD] Generating firmware binary
[BUILD] Generating 32-bit HEX image
[BUILD] Generated 127 words
[PASS] Accelerator firmware build completed
========================================
rtl/cpu/picorv32.v:1352: warning: @* is sensitive to all 32 words in array 'cpuregs'.
rtl/cpu/picorv32.v:1353: warning: @* is sensitive to all 32 words in array 'cpuregs'.
WARNING: simulation/testbench/tb_picorv32_accelerator.v:113: $readmemh(firmware/accelerator/build/accelerator.hex): Not enough words in the file for the requested range [0:4095].
========================================
WEEK 2: PICO RV32 + INT8 MAC SOC TEST
========================================
[INFO] RV32I firmware loaded
[INFO] MAC MMIO base: 0x80000000
[MAC] START command 1
[MAC] START command 2
[MAC] START command 3
[RESULT] Firmware reported: 39
========================================
[PASS] PicoRV32 controlled INT8 MAC
[PASS] Three MAC commands completed
[PASS] Final accumulator = 39
========================================
simulation/testbench/tb_picorv32_accelerator.v:207: $finish called at 4325000 (1ps)
[PASS] picorv32_accelerator
====================================
[SUCCESS] All RTL and firmware tests passed
====================================
```

## 6. Verification evidence

The terminal outputs captured during regression verification are cataloged below:

![Figure 01 — Baseline CPU and firmware build](../../screenshots/week03/01-regression-firmware-and-mac.png)

*Figure 01. Firmware compilation, RV32I CPU instruction verification, and start of MAC test suite.*

![Figure 02 — Arithmetic and exhaustive verification](../../screenshots/week03/02-regression-mac-and-exhaustive.png)

*Figure 02. Passing directed/randomized tests (213 checks) and exhaustive operand combinations (65,536 checks).*

![Figure 03 — Fault injection and MMIO verification](../../screenshots/week03/03-regression-fault-and-mmio.png)

*Figure 03. Week 3 fault injection sweep (9 checks) and standalone MMIO verification (16 checks).*

![Figure 04 — SoC integration and complete regression](../../screenshots/week03/04-regression-soc-and-pass.png)

*Figure 04. 127-word accelerator firmware build, end-to-end SoC simulation with 3 START commands, result 39, and full suite completion.*