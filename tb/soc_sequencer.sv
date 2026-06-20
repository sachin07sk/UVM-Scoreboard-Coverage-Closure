//=============================================================================
// soc_sequencer.sv — UVM Sequencer for soc_memory_ctrl
//=============================================================================

class soc_sequencer extends uvm_sequencer #(soc_seq_item);

  `uvm_component_utils(soc_sequencer)

  //-----------------------------------------------------------------------
  // Constructor
  //-----------------------------------------------------------------------
  function new(string name = "soc_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

endclass : soc_sequencer
