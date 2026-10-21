# Vivado Run Commands Reference

**Project:** RISC-V-Based Fault-Resilient AI Accelerator  
**Target Board:** ALINX AX7203 (Artix-7 XC7A200T-2FBG484I)  

---

## Quick Start via Convenience Shell Scripts

Instead of typing out long Vivado batch commands, you can use the pre-configured shell scripts inside this folder.

### 1. Run Without Hardware (Logical Checks & Reports)
Use this option for fast design iterations, checking logic utilization (synth_utilization.rpt), and verifying timing constraints without generating a bulky bitstream. Outputs are saved in a unique timestamped folder (vivado_build_YYYYMMDD_HHMMSS/).

```bash
cd vivado_run_command
./run_synth.sh
```

### 2. Run With Hardware (Full Implementation & Bitstream Generation)
Use this option when you are ready to program your physical FPGA board. It runs synthesis, place-and-route, generates the .bit file, and saves all outputs in a timestamped folder (vivado_hw_build_YYYYMMDD_HHMMSS/).

```bash
cd vivado_run_command
./run_hardware.sh
```

---

## Manual Vivado Batch Commands

If you prefer executing the Tcl scripts manually from the repository root:

### Logical Synthesis Check (No Bitstream)
```bash
vivado -mode batch -source scripts/run_synth.tcl | tee vivado_run_command/synth_log.txt
```

### Hardware Implementation & Bitstream Generation
```bash
vivado -mode batch -source scripts/run_hardware.tcl | tee vivado_run_command/hw_log.txt
```

---

## Programming the Physical ALINX AX7203 Board via Vivado GUI

1. Launch the Vivado GUI from your terminal:
   ```bash
   vivado &
   ```
2. Click Open Hardware Manager -> Open Target -> Auto Connect.
3. Right-click your xc7a200t target device and select Program Device.
4. Browse and select the generated .bit file located inside your latest vivado_hw_build_YYYYMMDD_HHMMSS/ folder.