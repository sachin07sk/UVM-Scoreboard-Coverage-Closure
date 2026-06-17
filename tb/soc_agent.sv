//=============================================================================
// soc_agent.sv — UVM Agent for soc_memory_ctrl
//=============================================================================

class soc_agent extends uvm_agent;

  `uvm_component_utils(soc_agent)

  //-----------------------------------------------------------------------
  // Component handles
  //-----------------------------------------------------------------------
  soc_driver     driver;
  soc_sequencer  sequencer;
  soc_monitor    monitor;

  //-----------------------------------------------------------------------
  // Constructor
  //-----------------------------------------------------------------------
  function new(string name = "soc_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //-----------------------------------------------------------------------
  // build_phase — create components
  //-----------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Monitor always created (passive or active)
    monitor = soc_monitor::type_id::create("monitor", this);

    // Driver + sequencer only in active mode
    if (get_is_active() == UVM_ACTIVE) begin
      driver    = soc_driver::type_id::create("driver", this);
      sequencer = soc_sequencer::type_id::create("sequencer", this);
    end
  endfunction : build_phase

  //-----------------------------------------------------------------------
  // connect_phase — connect driver to sequencer
  //-----------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction : connect_phase

endclass : soc_agent
