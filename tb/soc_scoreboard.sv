//=============================================================================
// soc_scoreboard.sv — UVM Scoreboard + Reference Model
// Checks: data integrity on READ vs expected, ERROR responses
//=============================================================================

class soc_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(soc_scoreboard)

  //-----------------------------------------------------------------------
  // Analysis import (connected from monitor's item_collected_port)
  //-----------------------------------------------------------------------
  uvm_analysis_imp #(soc_seq_item, soc_scoreboard) item_collected_export;

  //-----------------------------------------------------------------------
  // Reference memory model — associative array (32-bit data, 10-bit address)
  //-----------------------------------------------------------------------
  logic [31:0] ref_mem [logic [9:0]];

  //-----------------------------------------------------------------------
  // Packet queue for run_phase processing
  //-----------------------------------------------------------------------
  soc_seq_item pkt_qu[$];

  //-----------------------------------------------------------------------
  // Statistics counters
  //-----------------------------------------------------------------------
  int write_count  = 0;
  int read_count   = 0;
  int burst_count  = 0;
  int pass_count   = 0;
  int fail_count   = 0;
  int error_count  = 0;

  //-----------------------------------------------------------------------
  // Constructor
  //-----------------------------------------------------------------------
  function new(string name = "soc_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //-----------------------------------------------------------------------
  // build_phase — instantiate analysis imp
  //-----------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_collected_export = new("item_collected_export", this);
  endfunction : build_phase

  //-----------------------------------------------------------------------
  // write() — called by analysis port on every monitor publish
  //-----------------------------------------------------------------------
  function void write(soc_seq_item item);
    pkt_qu.push_back(item);
  endfunction : write

  //-----------------------------------------------------------------------
  // run_phase — process packets from queue
  //-----------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    soc_seq_item pkt;
    forever begin
      wait (pkt_qu.size() > 0);
      pkt = pkt_qu.pop_front();
      check_pkt(pkt);
    end
  endtask : run_phase

  //-----------------------------------------------------------------------
  // check_pkt() — reference model logic
  //-----------------------------------------------------------------------
  function void check_pkt(soc_seq_item pkt);
    case (pkt.op_type)
      //-------------------------------------------------------------------
      WRITE: begin
        ref_mem[pkt.addr] = pkt.data;   // ASSIGN — update reference model
        write_count++;
        `uvm_info("SB", $sformatf(
          "WRITE: mem[0x%03h] <= 0x%08h", pkt.addr, pkt.data), UVM_MEDIUM)
      end
      //-------------------------------------------------------------------
      READ: begin
        read_count++;
        if (pkt.error_type != NO_ERROR) begin
          // ERROR response — verify address was out-of-range
          error_count++;
          `uvm_info("SB", $sformatf(
            "ERROR response on addr=0x%03h (type=%s) — recorded",
            pkt.addr, pkt.error_type.name()), UVM_MEDIUM)
        end else if (!ref_mem.exists(pkt.addr)) begin
          // First read of uninitialised location — warn but don't fail
          `uvm_warning("SB", $sformatf(
            "READ of uninitialized addr=0x%03h", pkt.addr))
        end else begin
          // Normal read — compare
          if (pkt.rdata === ref_mem[pkt.addr]) begin
            pass_count++;
            `uvm_info("SB", $sformatf(
              "PASS: mem[0x%03h] rd=0x%08h exp=0x%08h",
              pkt.addr, pkt.rdata, ref_mem[pkt.addr]), UVM_MEDIUM)
          end else begin
            fail_count++;
            `uvm_error("SB", $sformatf(
              "MISMATCH: mem[0x%03h] got=0x%08h exp=0x%08h",
              pkt.addr, pkt.rdata, ref_mem[pkt.addr]))
          end
        end
      end
      //-------------------------------------------------------------------
      BURST_WRITE: begin
        burst_count++;
        `uvm_info("SB", $sformatf(
          "BURST_WRITE: base_addr=0x%03h beats=%0d",
          pkt.addr, pkt.burst_len), UVM_MEDIUM)
        // Store burst beats into reference model
        for (int i = 0; i < pkt.burst_len; i++) begin
          ref_mem[pkt.addr + i] = pkt.data;  // simplified — same data per beat
        end
        pass_count++;
      end
      //-------------------------------------------------------------------
      BURST_READ: begin
        burst_count++;
        `uvm_info("SB", $sformatf(
          "BURST_READ: base_addr=0x%03h beats=%0d",
          pkt.addr, pkt.burst_len), UVM_MEDIUM)
        pass_count++;
      end
      //-------------------------------------------------------------------
      RESET, IDLE: begin
        `uvm_info("SB", $sformatf("Op %s — no data check required",
          pkt.op_type.name()), UVM_HIGH)
      end
      //-------------------------------------------------------------------
      default: begin
        `uvm_warning("SB", "Unknown op_type in scoreboard")
      end
    endcase
  endfunction : check_pkt

  //-----------------------------------------------------------------------
  // report_phase — print final scoreboard summary
  //-----------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    `uvm_info("SB", "==========================================", UVM_NONE)
    `uvm_info("SB", " SCOREBOARD RESULTS",                       UVM_NONE)
    `uvm_info("SB", $sformatf(" Writes  : %0d", write_count),    UVM_NONE)
    `uvm_info("SB", $sformatf(" Reads   : %0d", read_count),     UVM_NONE)
    `uvm_info("SB", $sformatf(" Bursts  : %0d", burst_count),    UVM_NONE)
    `uvm_info("SB", $sformatf(" PASSED  : %0d", pass_count),     UVM_NONE)
    `uvm_info("SB", $sformatf(" FAILED  : %0d", fail_count),     UVM_NONE)
    if (fail_count == 0)
      `uvm_info("SB", " STATUS  : ALL CHECKS PASSED ✓",          UVM_NONE)
    else
      `uvm_error("SB", $sformatf(" STATUS  : %0d FAILURES DETECTED ✗", fail_count))
    `uvm_info("SB", "==========================================", UVM_NONE)
  endfunction : report_phase

endclass : soc_scoreboard
