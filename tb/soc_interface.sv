//=============================================================================
// soc_if.sv — Virtual Interface for soc_memory_ctrl
// DUT: 32-bit SoC Memory Controller
//      Data: 32-bit | Address: 10-bit (1KB) | Ops: READ/WRITE/BURST/RESET/IDLE
//=============================================================================

interface soc_if(input logic clk, reset);

  //-----------------------------------------------------------------------
  // DUT Signals
  //-----------------------------------------------------------------------
  logic        wr_en;
  logic        rd_en;
  logic [9:0]  addr;
  logic [31:0] wdata;
  logic [31:0] rdata;
  logic [3:0]  burst_len;   // 1–16 beats
  logic        burst_wr;
  logic        burst_rd;
  logic        valid;
  logic        error;       // out-of-range address
  logic        align_error; // unaligned access

  //-----------------------------------------------------------------------
  // Driver Clocking Block
  //-----------------------------------------------------------------------
  clocking driver_cb @(posedge clk);
    default input #1 output #1;
    output wr_en, rd_en, addr, wdata, burst_len, burst_wr, burst_rd;
    input  rdata, valid, error, align_error;
  endclocking

  //-----------------------------------------------------------------------
  // Monitor Clocking Block
  //-----------------------------------------------------------------------
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input wr_en, rd_en, addr, wdata, burst_len, burst_wr, burst_rd;
    input rdata, valid, error, align_error;
  endclocking

  //-----------------------------------------------------------------------
  // Modports
  //-----------------------------------------------------------------------
  modport DRIVER  (clocking driver_cb,  input clk, reset);
  modport MONITOR (clocking monitor_cb, input clk, reset);

endinterface : soc_if
