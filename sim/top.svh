//=============================================================================
// top.svh — Include chain in strict UVM compile order
//=============================================================================

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "soc_if.sv"
`include "soc_seq_item.sv"
`include "soc_sequences.sv"
`include "soc_sequencer.sv"
`include "soc_driver.sv"
`include "soc_monitor.sv"
`include "soc_agent.sv"
`include "soc_scoreboard.sv"
`include "soc_coverage.sv"
`include "soc_env.sv"
`include "soc_base_test.sv"
`include "soc_test.sv"
