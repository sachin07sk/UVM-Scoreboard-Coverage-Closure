//=============================================================================
// soc_base_test.sv — UVM Base Test for soc_memory_ctrl
//=============================================================================

class soc_base_test extends uvm_test;

  `uvm_component_utils(soc_base_test)

  //-----------------------------------------------------------------------
  // Environment handle
  //-----------------------------------------------------------------------
  soc_env env;

  //-----------------------------------------------------------------------
  // Constructor
  //-----------------------------------------------------------------------
  function new(string name = "soc_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //-----------------------------------------------------------------------
  // build_phase — create environment
  //-----------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = soc_env::type_id::create("env", this);
  endfunction : build_phase

  //-----------------------------------------------------------------------
  // end_of_elaboration — print topology
  //-----------------------------------------------------------------------
  function void end_of_elaboration_phase(uvm_phase phase);
    print();
  endfunction : end_of_elaboration_phase

  //-----------------------------------------------------------------------
  // report_phase — print TEST PASS / TEST FAIL banner
  //-----------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    svr = uvm_report_server::get_server();
    if (svr.get_severity_count(UVM_FATAL) +
        svr.get_severity_count(UVM_ERROR) == 0) begin
      `uvm_info(get_type_name(),
        "\n===========================================\n  TEST PASS ✓\n===========================================",
        UVM_NONE)
    end else begin
      `uvm_info(get_type_name(),
        "\n===========================================\n  TEST FAIL ✗\n===========================================",
        UVM_NONE)
    end
  endfunction : report_phase

endclass : soc_base_test
