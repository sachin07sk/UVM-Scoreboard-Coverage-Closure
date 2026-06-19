//=============================================================================
// soc_env.sv — UVM Environment for soc_memory_ctrl
// Connects: agent → scoreboard + coverage collector
//=============================================================================

class soc_env extends uvm_env;

  `uvm_component_utils(soc_env)

  //-----------------------------------------------------------------------
  // Component handles
  //-----------------------------------------------------------------------
  soc_agent      mem_agnt;
  soc_scoreboard mem_scb;
  soc_coverage   mem_cov;

  //-----------------------------------------------------------------------
  // Constructor
  //-----------------------------------------------------------------------
  function new(string name = "soc_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //-----------------------------------------------------------------------
  // build_phase — create agent, scoreboard, coverage
  //-----------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mem_agnt = soc_agent::type_id::create("mem_agnt",  this);
    mem_scb  = soc_scoreboard::type_id::create("mem_scb",   this);
    mem_cov  = soc_coverage::type_id::create("mem_cov",    this);
  endfunction : build_phase

  //-----------------------------------------------------------------------
  // connect_phase — wire monitor analysis port to scoreboard and coverage
  //-----------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    mem_agnt.monitor.item_collected_port.connect(mem_scb.item_collected_export);
    mem_agnt.monitor.item_collected_port.connect(mem_cov.analysis_export);
  endfunction : connect_phase

endclass : soc_env
