//=============================================================================
// soc_top.sv — Simulation Top Module for soc_memory_ctrl
// Generates clk/reset, instantiates DUT and interface, kicks off UVM test
//=============================================================================

`include "top.svh"

module tbench_top;

  //-----------------------------------------------------------------------
  // Clock and reset signals
  //-----------------------------------------------------------------------
  logic clk;
  logic reset;

  //-----------------------------------------------------------------------
  // Clock generation: 10 ns period (100 MHz)
  //-----------------------------------------------------------------------
  initial clk = 0;
  always #5 clk = ~clk;

  //-----------------------------------------------------------------------
  // Synchronous active-HIGH reset
  //-----------------------------------------------------------------------
  initial begin
    reset = 1;
    #50;          // hold reset for 5 clock cycles
    @(posedge clk);
    #1;
    reset = 0;
  end

  //-----------------------------------------------------------------------
  // Interface instantiation
  //-----------------------------------------------------------------------
  soc_if intf(.clk(clk), .reset(reset));

  //-----------------------------------------------------------------------
  // DUT instantiation — soc_memory_ctrl
  //-----------------------------------------------------------------------
  soc_memory_ctrl DUT (
    .clk         (clk),
    .reset       (reset),
    .wr_en       (intf.wr_en),
    .rd_en       (intf.rd_en),
    .addr        (intf.addr),
    .wdata       (intf.wdata),
    .rdata       (intf.rdata),
    .burst_len   (intf.burst_len),
    .burst_wr    (intf.burst_wr),
    .burst_rd    (intf.burst_rd),
    .valid       (intf.valid),
    .error       (intf.error),
    .align_error (intf.align_error)
  );

  //-----------------------------------------------------------------------
  // UVM config_db — publish virtual interface to all components
  //-----------------------------------------------------------------------
  initial begin
    uvm_config_db #(virtual soc_if)::set(uvm_root::get(), "*", "vif", intf);
  end

  //-----------------------------------------------------------------------
  // Start UVM test
  //-----------------------------------------------------------------------
  initial begin
    run_test("soc_test");
  end

endmodule : tbench_top
