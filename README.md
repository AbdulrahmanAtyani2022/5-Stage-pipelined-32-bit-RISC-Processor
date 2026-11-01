# 32-bit 5-Stage Pipelined RISC Processor (Verilog)

Design and verification of a simple pipelined RISC processor written in Verilog.
Course project for **ENCS4370 – Computer Architecture** (Spring 2024/2025),
Department of Electrical and Computer Engineering.

---

## Overview

This project implements a 32-bit, single-format RISC processor with a classic
**5-stage pipeline** (Fetch → Decode → Execute → Memory → Write-Back), including
hazard detection, data forwarding, branch/jump handling, and support for
double-word load/store instructions (`LDW` / `SDW`).

### Processor specifications

| Feature | Value |
|---|---|
| Word / instruction size | 32 bits |
| General-purpose registers | 16 × 32-bit (`R0`–`R15`) |
| `R15` | Program Counter (PC) |
| `R14` | Return address register (used by `CLL`) |
| Memories | Separate instruction and data memory (256 words each) |
| Addressing | Word addressable |
| Instruction format | Single type (see below) |

### Instruction format

```
 31      26 25    22 21    18 17    14 13               0
+----------+--------+--------+--------+------------------+
| Opcode(6)| Rd (4) | Rs (4) | Rt (4) |     Imm (14)     |
+----------+--------+--------+--------+------------------+
```

The immediate is zero-extended for logical instructions and sign-extended
otherwise. For `BZ`, `BGZ`, `BLZ`, `J` and `CLL`, the target address is
`PC + sign_extended(Imm)`. Unused fields are encoded as zero.

---

## Instruction Set

| Opcode | Instruction | Operation |
|:---:|---|---|
| 0 | `OR  Rd, Rs, Rt` | `Rd = Rs \| Rt` |
| 1 | `ADD Rd, Rs, Rt` | `Rd = Rs + Rt` |
| 2 | `SUB Rd, Rs, Rt` | `Rd = Rs - Rt` |
| 3 | `CMP Rd, Rs, Rt` | `Rd = 0` if equal, `-1` if `Rs < Rt`, `1` if `Rs > Rt` |
| 4 | `ORI Rd, Rs, Imm` | `Rd = Rs \| Imm` |
| 5 | `ADDI Rd, Rs, Imm` | `Rd = Rs + Imm` |
| 6 | `LW  Rd, Imm(Rs)` | `Rd = Mem[Rs + Imm]` |
| 7 | `SW  Rd, Imm(Rs)` | `Mem[Rs + Imm] = Rd` |
| 8 | `LDW Rd, Imm(Rs)` | `Rd = Mem[Rs + Imm]`, then `Rd+1 = Mem[Rs + Imm + 1]` (2 cycles) |
| 9 | `SDW Rd, Imm(Rs)` | `Mem[Rs + Imm] = Rd`, then `Mem[Rs + Imm + 1] = Rd+1` (2 cycles) |
| 10 | `BZ  Rs, Label` | Branch if `Rs == 0` |
| 11 | `BGZ Rs, Label` | Branch if `Rs > 0` |
| 12 | `BLZ Rs, Label` | Branch if `Rs < 0` |
| 13 | `JR  Rs` | Jump to address in `Rs` |
| 14 | `J   Label` | Unconditional jump |
| 15 | `CLL Label` | Call: jump to label, return address saved in `R14` |

---

## Microarchitecture

### Pipeline stages

1. **IF – Instruction Fetch:** `FetchStage`, `ProgramCounter`, `PCAdder`, `InstructionMemory`
2. **ID – Instruction Decode:** `ID` (control unit), `Register_File`, `sign_exdend`, `Branch`, `jump`
3. **EX – Execute:** `ALU` (OR / ADD / SUB / CMP)
4. **MEM – Memory Access:** `DataMemory`
5. **WB – Write Back:** write-back mux and register file write port

Pipeline registers: `IF_reg_out`, `instruction_ID`, `ID_reg_out`, `ALU_reg_out`, `DataMemory_reg`.

### Hazard handling

- **`Hazard_Detect_and_forward`** compares the source/destination registers
  across pipeline stages and drives the forwarding multiplexers (`mux4_1`) that
  feed operands `Rs`, `Rt`, and `Rd` from the register file or from later pipeline stages.
- **`pc_control`** handles control hazards and stalls: it selects the next PC
  (`pc_sel`), controls the pipeline enable signals, and flushes/replaces the
  fetched instruction when required.

### LDW / SDW implementation

When `LDW` / `SDW` is detected in the decode stage, the fetch of a new
instruction is suppressed for one cycle. The `Lw` / `Sw` modules generate the
second micro-operation (`Rd + 1`, `Imm + 1`) and inject it into the pipeline,
so the two words are handled in two consecutive cycles.

### Module list

| Module | Description |
|---|---|
| `main` | Top-level module (processor + reset generation) |
| `FetchStage`, `ProgramCounter`, `PCAdder` | Fetch logic and PC |
| `InstructionMemory`, `DataMemory` | Memories (loaded with `$readmemh`) |
| `ID` | Instruction decoder / control signal generation |
| `Register_File` | 16 × 32-bit register file |
| `ALU` | Arithmetic/logic unit |
| `Hazard_Detect_and_forward` | Hazard detection and forwarding control |
| `pc_control` | PC / stall / flush control |
| `Branch`, `jump` | Branch and jump target calculation |
| `Lw`, `Sw`, `kill_reg` | LDW/SDW second-cycle instruction generation and bubble insertion |
| `IF_reg_out`, `instruction_ID`, `ID_reg_out`, `ALU_reg_out`, `DataMemory_reg` | Pipeline registers |
| `mux2_1`, `mux2_1fourbit`, `mux4_1`, `register`, `register_4bit`, `sign_exdend` | Helper components |

---

## Repository Structure

```
.
├── Code/
│   ├── src/
│   │   ├── data_path.v          # Full RTL design (all modules, top module: main)
│   │   └── instructions.mem     # Program loaded into instruction memory (hex)
│   └── data_path.adf / .aws / .wsp ...   # Aldec Active-HDL project files
├── Datapath/
│   ├── Divider.pdf              # Datapath diagram (PDF)
│   └── Divider.jpeg             # Datapath diagram (image)
├── Report/                      # Project report and guidelines
└── Project-2-Spring-2024-2025.pdf   # Project specification
```

---

## Getting Started

### Requirements

- **Aldec Active-HDL** (the project was developed and simulated with the
  Student Edition), or any Verilog/SystemVerilog simulator that supports
  `$readmemh` (e.g. ModelSim/Questa, Icarus Verilog with minor adjustments).

### Running the simulation (Active-HDL)

1. Open the workspace file `Code/data_path.aws` in Active-HDL.
2. Compile `src/data_path.v` (compiled with SystemVerilog 2017 mode, `-sv2k17`).
3. Set `main` as the top-level module and initialize the simulation.
4. Make sure `instructions.mem` (and `data.mem` for the data memory) are in
   the simulator's working directory.
5. Run the simulation, e.g. `run 4000ns`, and inspect the waveforms and the console output.

The console prints the register file contents (`R0`–`R15`) and every data
memory write (`at address X , we write Y`).

### Running a custom program

Instructions are stored as one 32-bit hex word per line in `instructions.mem`:

```
20080000   // LDW R0, 0(R2)
24080000   // SDW R0, 0(R2)
```

Initial data memory contents are loaded from `data.mem` in the same format.
Reset is asserted for the first 20 ns of simulation.

---

## Verification

The design is verified by simulation: test programs written in the processor's
ISA are loaded into the instruction memory, executed, and the results are
checked using waveform diagrams and console output (register file dump and
data memory writes). The test programs cover all supported instructions,
data/control hazards, forwarding, and double-word load/store behavior.

Test programs (assembly and binary), waveforms, and screenshots are documented
in the project report under `Report/`.

---

## Known Limitations

- Instruction and data memories are limited to 256 words.
- Raising an exception for `LDW` / `SDW` with an odd register number is part of
  the specification; check the RTL/report for the current status of this feature.

---



## Acknowledgments

Developed as part of the **ENCS4370 – Computer Architecture** course.
Course project specification: `Project-2-Spring-2024-2025.pdf`.
