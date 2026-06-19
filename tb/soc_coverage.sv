//=============================================================================
// soc_coverage.sv — Functional Coverage Collector
// Covergroups: op_type_cg, addr_range_cg, burst_len_cg,
//              data_pattern_cg, cross_cg (op × zone)
//=============================================================================

class soc_coverage extends uvm_subscriber #(soc_seq_item);

  `uvm_component_utils(soc_coverage)

  //-----------------------------------------------------------------------
  // Current transaction handle (used inside covergroups)
  //-----------------------------------------------------------------------
  soc_seq_item item;

  //-----------------------------------------------------------------------
  // Covergroup 1 — Operation Type Coverage
  // Target: all 6 op types exercised
  //-----------------------------------------------------------------------
  covergroup op_type_cg;
    cp_op: coverpoint item.op_type {
      bins write_op    = {WRITE};
      bins read_op     = {READ};
      bins burst_write = {BURST_WRITE};
      bins burst_read  = {BURST_READ};
      bins reset_op    = {RESET};
      bins idle_op     = {IDLE};
    }
  endgroup

  //-----------------------------------------------------------------------
  // Covergroup 2 — Address Range Coverage (addr[9:8] → zone 0-3)
  // Target: all 4 memory zones accessed
  //-----------------------------------------------------------------------
  covergroup addr_range_cg;
    cp_addr: coverpoint item.addr[9:8] {
      bins zone0 = {2'b00};  // 0x000 – 0x0FF
      bins zone1 = {2'b01};  // 0x100 – 0x1FF
      bins zone2 = {2'b10};  // 0x200 – 0x2FF
      bins zone3 = {2'b11};  // 0x300 – 0x3FF
    }
  endgroup

  //-----------------------------------------------------------------------
  // Covergroup 3 — Burst Length Coverage
  // Target: single, short, medium, long burst ranges
  //-----------------------------------------------------------------------
  covergroup burst_len_cg;
    cp_len: coverpoint item.burst_len {
      bins single      = {1};
      bins short_burst = {[2:4]};
      bins med_burst   = {[5:8]};
      bins long_burst  = {[9:16]};
    }
  endgroup

  //-----------------------------------------------------------------------
  // Covergroup 4 — Data Pattern Coverage
  // Target: all_zeros, all_ones, walking_one, random
  //-----------------------------------------------------------------------
  covergroup data_pattern_cg;
    cp_data: coverpoint item.data {
      bins all_zeros   = {32'h00000000};
      bins all_ones    = {32'hFFFFFFFF};
      bins walking_one = {32'h00000001, 32'h00000002,
                          32'h00000004, 32'h00000008};
      bins random_data = default;
    }
  endgroup

  //-----------------------------------------------------------------------
  // Covergroup 5 — Cross Coverage (op_type × address zone)
  // Target: READ and WRITE exercised in ALL 4 zones → 8 cross bins
  //-----------------------------------------------------------------------
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
    cx_op_zone: cross cp_op, cp_zone;
  endgroup

  //-----------------------------------------------------------------------
  // Constructor — instantiate all covergroups
  //-----------------------------------------------------------------------
  function new(string name = "soc_coverage", uvm_component parent = null);
    super.new(name, parent);
    op_type_cg      = new();
    addr_range_cg   = new();
    burst_len_cg    = new();
    data_pattern_cg = new();
    cross_cg        = new();
  endfunction : new

  //-----------------------------------------------------------------------
  // write() — called every time monitor publishes a transaction
  //-----------------------------------------------------------------------
  function void write(soc_seq_item t);
    item = t;
    op_type_cg.sample();
    addr_range_cg.sample();
    burst_len_cg.sample();
    if (item.op_type inside {WRITE, BURST_WRITE})
      data_pattern_cg.sample();
    if (item.op_type inside {WRITE, READ})
      cross_cg.sample();
  endfunction : write

  //-----------------------------------------------------------------------
  // report_phase — print coverage summary
  //-----------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    real op_cov    = op_type_cg.get_coverage();
    real addr_cov  = addr_range_cg.get_coverage();
    real burst_cov = burst_len_cg.get_coverage();
    real data_cov  = data_pattern_cg.get_coverage();
    real cross_cov = cross_cg.get_coverage();
    real overall   = (op_cov + addr_cov + burst_cov + data_cov + cross_cov) / 5.0;

    `uvm_info("COV", "==========================================", UVM_NONE)
    `uvm_info("COV", " COVERAGE REPORT",                          UVM_NONE)
    `uvm_info("COV", $sformatf(" op_type_cg       : %0.1f%%",  op_cov),    UVM_NONE)
    `uvm_info("COV", $sformatf(" addr_range_cg    : %0.1f%%",  addr_cov),  UVM_NONE)
    `uvm_info("COV", $sformatf(" burst_len_cg     : %0.1f%%",  burst_cov), UVM_NONE)
    `uvm_info("COV", $sformatf(" data_pattern_cg  : %0.1f%%",  data_cov),  UVM_NONE)
    `uvm_info("COV", $sformatf(" cross_cg         : %0.1f%%",  cross_cov), UVM_NONE)
    `uvm_info("COV", " ─────────────────────────────",            UVM_NONE)
    `uvm_info("COV", $sformatf(" OVERALL COVERAGE : %0.1f%%",  overall),   UVM_NONE)
    if (overall >= 100.0)
      `uvm_info("COV", " STATUS           : SIGN-OFF COMPLETE ✓",  UVM_NONE)
    else
      `uvm_warning("COV", $sformatf(
        " STATUS           : COVERAGE INCOMPLETE (%.1f%%) — add targeted tests", overall))
    `uvm_info("COV", "==========================================", UVM_NONE)
  endfunction : report_phase

endclass : soc_coverage
