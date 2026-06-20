//=============================================================================
// soc_test.sv — Regression Test (runs full regression_seq)
//=============================================================================

class soc_test extends soc_base_test;

  `uvm_component_utils(soc_test)

  //-----------------------------------------------------------------------
  // Sequence handle
  //-----------------------------------------------------------------------
  regression_seq reg_seq;

  //-----------------------------------------------------------------------
  // Constructor
  //-----------------------------------------------------------------------
  function new(string name = "soc_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //-----------------------------------------------------------------------
  // build_phase — create regression sequence
  //-----------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    reg_seq = regression_seq::type_id::create("reg_seq");
  endfunction : build_phase

  //-----------------------------------------------------------------------
  // run_phase — run regression, then drop objection
  //-----------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(),
      "\n===========================================\n UVM Scoreboard & Coverage — Start\n===========================================",
      UVM_NONE)

    reg_seq.start(env.mem_agnt.sequencer);

    // Drain time: allow remaining transactions to propagate
    #200;
    phase.drop_objection(this);
  endtask : run_phase

endclass : soc_test
