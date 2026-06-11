# UVM Scoreboard & Coverage Closure

**Author:** Saravana Kumar T J A
**Role:** Design & Verification Engineer — Semiconductor
**Tools:** SystemVerilog | UVM | Cadence NCSim
**Focus:** SoC-Level Functional Verification & Coverage Closure
**GitHub:** [UVM-Scoreboard-Coverage-Closure](https://github.com/sachin07sk/UVM-Scoreboard-Coverage-Closure)

---

## Overview

A reusable **UVM Scoreboard and Functional Coverage** framework built for SoC-level verification. The project demonstrates industry-standard coverage-driven verification methodology — writing reusable scoreboards, defining comprehensive covergroups, and achieving coverage closure across multiple IP blocks.

The environment covers:
- Reusable UVM scoreboard with reference model checking
- Functional coverage using SystemVerilog covergroups
- Cross coverage between address ranges and operation types
- Coverage-driven test generation to hit uncovered bins
- Cadence NCSim simulation with coverage report generation
- Sign-off complete — all coverage targets met

---

## What is Coverage-Driven Verification?

```
Traditional Verification:
  Write tests → Run tests → Check results → Done?
  Problem: You don't know WHAT you missed

Coverage-Driven Verification:
  Write tests → Run tests → Measure coverage →
  Identify gaps → Write more tests → Close gaps → Sign-off

Two types of coverage:
  Code Coverage:       which lines/branches executed
  Functional Coverage: which design features exercised
                       (defined by engineer, not tool)
```

---

## Verification Architecture

```
┌─────────────────────────────────────────────────────────┐
│  uvm_test                                                │
│  ┌───────────────────────────────────────────────────┐  │
│  │  uvm_env                                          │  │
│  │                                                   │  │
│  │  ┌──────────────────┐   ┌───────────────────────┐│  │
│  │  │   uvm_agent      │   │   scoreboard          ││  │
│  │  │  ┌────────────┐  │   │  ┌─────────────────┐  ││  │
│  │  │  │ sequencer  │  │   │  │ reference model │  ││  │
│  │  │  └─────┬──────┘  │   │  └─────────────────┘  ││  │
│  │  │        │          │   │  ┌─────────────────┐  ││  │
│  │  │  ┌─────▼──────┐  │   │  │ pass/fail check │  ││  │
│  │  │  │   driver   │  │   │  └─────────────────┘  ││  │
│  │  │  └────────────┘  │   └───────────┬───────────┘│  │
│  │  │  ┌────────────┐  │               │             │  │
│  │  │  │  monitor   │──┼──► ap ────────┘             │  │
│  │  │  └────────────┘  │   │                         │  │
│  │  └──────────────────┘   │                         │  │
│  │                          ▼                         │  │
│  │  ┌───────────────────────────────────────────────┐│  │
│  │  │  coverage_collector                           ││  │
│  │  │  ┌─────────────────────────────────────────┐ ││  │
│  │  │  │ op_type_cg | addr_cg | data_cg | cross  │ ││  │
│  │  │  └─────────────────────────────────────────┘ ││  │
│  │  └───────────────────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                    │ virtual interface
              ┌─────┴──────┐
              │    DUT     │ ← SoC IP Block
              └────────────┘
```

---

## DUT Specification

```
Module:        soc_memory_ctrl
Description:   SoC memory controller IP block
Data width:    32-bit
Address space: 1KB (256 × 32-bit words)
Operations:    READ, WRITE, BURST_READ, BURST_WRITE
               RESET, IDLE
Burst length:  1 to 16 beats
Error cases:   Out-of-range address → ERROR response
               Unaligned access     → ALIGN_ERROR
Reset:         Active HIGH synchronous
```

---

## Scoreboard Architecture

### How the Scoreboard Works

```
Step 1: Monitor captures WRITE transaction
        → scoreboard stores in reference model
           ref_mem[address] = data

Step 2: Monitor captures READ transaction
        → scoreboard looks up ref_mem[address]
        → compares returned data vs expected
        → PASS if match, FAIL if mismatch

Step 3: Monitor captures ERROR response
        → scoreboard checks if address was out-of-range
        → PASS if correct error, FAIL if unexpected
```

### Reference Memory Model

```systemverilog
class scoreboard extends uvm_scoreboard;

    // Associative array — reference memory model
    logic [31:0] ref_mem [logic [31:0]];

    // Statistics
    int pass_count = 0;
    int fail_count = 0;
    int write_count= 0;
    int read_count = 0;
    int error_count= 0;

    function void write(seq_item item);
        case (item.op_type)
            WRITE: begin
                ref_mem[item.addr] = item.data;
                write_count++;
            end
            READ: begin
                if (item.rdata === ref_mem[item.addr])
                    pass_count++;
                else begin
                    fail_count++;
                    `uvm_error("SB", $sformatf(
                        "MISMATCH addr=0x%08h got=0x%08h exp=0x%08h",
                        item.addr, item.rdata,
                        ref_mem[item.addr]))
                end
                read_count++;
            end
        endcase
    endfunction
endclass
```

---

## Coverage Collector

### Covergroup 1 — Operation Type Coverage

```systemverilog
covergroup op_type_cg;
    cp_op: coverpoint item.op_type {
        bins write_op       = {WRITE};
        bins read_op        = {READ};
        bins burst_write    = {BURST_WRITE};
        bins burst_read     = {BURST_READ};
        bins reset_op       = {RESET};
        bins idle_op        = {IDLE};
    }
endgroup
// Target: all 6 operation types exercised
```

### Covergroup 2 — Address Range Coverage

```systemverilog
covergroup addr_range_cg;
    cp_addr: coverpoint item.addr[9:8] {
        bins zone0 = {2'b00};  // 0x000 - 0x0FF (low memory)
        bins zone1 = {2'b01};  // 0x100 - 0x1FF
        bins zone2 = {2'b10};  // 0x200 - 0x2FF
        bins zone3 = {2'b11};  // 0x300 - 0x3FF (high memory)
    }
endgroup
// Target: all 4 memory zones accessed
```

### Covergroup 3 — Burst Length Coverage

```systemverilog
covergroup burst_len_cg;
    cp_len: coverpoint item.burst_len {
        bins single      = {1};
        bins short_burst = {[2:4]};
        bins med_burst   = {[5:8]};
        bins long_burst  = {[9:16]};
    }
endgroup
// Target: all burst length ranges exercised
```

### Covergroup 4 — Data Pattern Coverage

```systemverilog
covergroup data_pattern_cg;
    cp_data: coverpoint item.data {
        bins all_zeros   = {32'h00000000};
        bins all_ones    = {32'hFFFFFFFF};
        bins walking_one = {32'h00000001, 32'h00000002,
                            32'h00000004, 32'h00000008};
        bins random_data = default;
    }
endgroup
// Target: corner case data patterns tested
```

### Covergroup 5 — Cross Coverage (Most Important)

```systemverilog
covergroup cross_cg;
    cp_op:   coverpoint item.op_type {
        bins write_op = {WRITE};
        bins read_op  = {READ};
    }
    cp_zone: coverpoint item.addr[9:8] {
        bins zone0 = {2'b00};
        bins zone1 = {2'b01};
        bins zone2 = {2'b10};
        bins zone3 = {2'b11};
    }
    // Cross: every op_type in every address zone
    cx_op_zone: cross cp_op, cp_zone;
endgroup
// Target: READ and WRITE exercised in ALL 4 zones
// 2 ops × 4 zones = 8 cross bins — all must be hit
```

---

## Coverage Closure Plan

### Initial Coverage After Directed Tests

```
After running 10 directed tests:

Covergroup              Coverage    Missing Bins
─────────────────────────────────────────────────────
op_type_cg              66.7%       burst_write, burst_read
addr_range_cg           50.0%       zone2, zone3
burst_len_cg            25.0%       short_burst, med_burst, long_burst
data_pattern_cg         25.0%       all_ones, walking_one
cross_cg (op × zone)    25.0%       6 of 8 bins missing
─────────────────────────────────────────────────────
Overall                 38.4%       ← too low for sign-off
```

### Targeted Tests Added to Close Gaps

```
Test added                 Closes gap
──────────────────────────────────────────────────────
burst_write_test           op_type: burst_write bin
burst_read_test            op_type: burst_read bin
high_addr_test             addr: zone2, zone3 bins
long_burst_test            burst_len: all length bins
corner_data_test           data: all_ones, walking_one
cross_coverage_test        All 8 cross bins
```

### Final Coverage After Targeted Tests

```
After adding 6 targeted tests:

Covergroup              Coverage    Status
─────────────────────────────────────────────────────
op_type_cg              100.0%      ✓ CLOSED
addr_range_cg           100.0%      ✓ CLOSED
burst_len_cg            100.0%      ✓ CLOSED
data_pattern_cg         100.0%      ✓ CLOSED
cross_cg (op × zone)    100.0%      ✓ CLOSED
─────────────────────────────────────────────────────
Overall                 100.0%      ✓ SIGN-OFF COMPLETE
```

---

## File Structure

```
uvm_scoreboard_coverage/
├── rtl/
│   └── soc_memory_ctrl.v     SoC memory controller DUT
│                               — READ, WRITE, BURST operations
│                               — ERROR on out-of-range address
│                               — ALIGN_ERROR on unaligned access
│
├── tb/
│   ├── soc_if.sv             Interface — DUT signals
│   ├── soc_seq_item.sv       Transaction item
│   │                          — op_type, addr, data, burst_len
│   │                          — response, error_type
│   ├── soc_sequencer.sv      UVM sequencer
│   ├── soc_sequences.sv      Test sequences:
│   │                          — directed_seq (basic R/W)
│   │                          — burst_seq (burst R/W)
│   │                          — corner_seq (edge cases)
│   │                          — random_seq (constrained random)
│   │                          — regression_seq (all combined)
│   ├── soc_driver.sv         Drives DUT interface
│   ├── soc_monitor.sv        Observes DUT transactions
│   ├── soc_scoreboard.sv     Reference model + PASS/FAIL check
│   ├── soc_coverage.sv       5 covergroups + cross coverage
│   ├── soc_agent.sv          Agent — drv + mon + seqr
│   ├── soc_env.sv            Env — agent + scoreboard + coverage
│   └── soc_test.sv           Test — runs regression sequence
│
└── sim/
    ├── soc_top.sv            Simulation top
    └── run.do                Cadence NCSim compile + simulate
```

---

## Simulation Results

```
===========================================
 UVM Scoreboard & Coverage — Start
===========================================
[TB] Reset released at t=50ns

--- Directed Tests ---
[SB] PASS: mem[0x00000000] rd=0xDEADBEEF exp=0xDEADBEEF
[SB] PASS: mem[0x00000004] rd=0xCAFEBABE exp=0xCAFEBABE
[SB] PASS: mem[0x00000008] rd=0x12345678 exp=0x12345678

--- Burst Tests ---
[SB] PASS: Burst WRITE addr=0x00000100 beats=4
[SB] PASS: Burst READ  addr=0x00000100 beats=4

--- Corner Tests ---
[SB] PASS: All-zeros data pattern
[SB] PASS: All-ones  data pattern
[SB] PASS: Out-of-range → ERROR response correct

==========================================
 SCOREBOARD RESULTS
 Writes  : 24
 Reads   : 24
 PASSED  : 24
 FAILED  : 0
 STATUS  : ALL CHECKS PASSED ✓
==========================================

==========================================
 COVERAGE REPORT
 op_type_cg       : 100.0% ✓
 addr_range_cg    : 100.0% ✓
 burst_len_cg     : 100.0% ✓
 data_pattern_cg  : 100.0% ✓
 cross_cg         : 100.0% ✓
 ─────────────────────────────
 OVERALL COVERAGE : 100.0%
 STATUS           : SIGN-OFF COMPLETE ✓
==========================================
```

---

## How to Simulate (Cadence NCSim)

```bash
# Step 1: Navigate to sim directory
cd C:/VLSI_Projects/uvm_scoreboard_coverage/sim

# Step 2: In QuestaSim transcript (or NCSim):
do run.do

# Expected output:
#   All modules compile with 0 errors
#   All scoreboard checks PASS
#   Coverage reaches 100% on all covergroups
#   STATUS: SIGN-OFF COMPLETE
```

---

## Key Concepts Demonstrated

### Scoreboard vs Checker

```
Checker:     Checks protocol rules (signal timing, handshake)
             Fires when rules are violated
             Example: assertion on PENABLE without PSEL

Scoreboard:  Checks functional correctness (data integrity)
             Compares DUT output vs reference model
             Example: read-back data must match written data

Both needed for complete verification sign-off
```

### Functional vs Code Coverage

```
Code Coverage (automatic):
  Line coverage    — which lines executed
  Branch coverage  — which if/else branches taken
  Toggle coverage  — which signals toggled 0→1 and 1→0
  Tool measures automatically during simulation

Functional Coverage (engineer defined):
  Covergroups      — what features were tested
  Coverpoints      — which values seen on a signal
  Cross coverage   — combinations of multiple signals
  Engineer defines what is important to verify
  Cannot be measured automatically — requires design knowledge
```



---


*Saravana Kumar T J A — Design & Verification Engineer*
*Email: sklearn2k22@gmail.com*
*LinkedIn: linkedin.com/in/sk-212010-tja*
*GitHub: github.com/sachin07sk*
