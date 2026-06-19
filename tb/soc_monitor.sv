//=============================================================================
// soc_monitor.sv — UVM Monitor for soc_memory_ctrl
//=============================================================================

class soc_monitor extends uvm_monitor;

  `uvm_component_utils(soc_monitor)

  //-----------------------------------------------------------------------
  // Analysis port
  //-----------------------------------------------------------------------
  uvm_analysis_port #(soc_seq_item) item_collected_port;

  //-----------------------------------------------------------------------
  // Virtual interface handle
  //-----------------------------------------------------------------------
  virtual soc_if vif;

  //-----------------------------------------------------------------------
  // Internal transaction handle (allocated once)
  //-----------------------------------------------------------------------
  soc_seq_item trans_collected;

  //-----------------------------------------------------------------------
  // Constructor
  //-----------------------------------------------------------------------
  function new(string name = "soc_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction : new

  //-----------------------------------------------------------------------
  // build_phase — retrieve virtual interface
  //-----------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual soc_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", {"Virtual interface must be set for: ", get_full_name()})
  endfunction : build_phase

  //-----------------------------------------------------------------------
  // run_phase — sample DUT transactions and publish to analysis port
  //-----------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.MONITOR.clk);

      //-------------------------------------------------------------------
      // Detect WRITE
      //-------------------------------------------------------------------
      if (vif.monitor_cb.wr_en === 1'b1) begin
        trans_collected = soc_seq_item::type_id::create("trans_collected");
        trans_collected.op_type  = WRITE;
        trans_collected.addr     = vif.monitor_cb.addr;
        trans_collected.data     = vif.monitor_cb.wdata;
        trans_collected.burst_len = 1;
        trans_collected.error_type = NO_ERROR;
        @(posedge vif.MONITOR.clk);
        item_collected_port.write(trans_collected);
      end

      //-------------------------------------------------------------------
      // Detect READ
      //-------------------------------------------------------------------
      else if (vif.monitor_cb.rd_en === 1'b1) begin
        trans_collected = soc_seq_item::type_id::create("trans_collected");
        trans_collected.op_type  = READ;
        trans_collected.addr     = vif.monitor_cb.addr;
        trans_collected.burst_len = 1;
        @(posedge vif.MONITOR.clk);  // capture response on next cycle
        trans_collected.rdata      = vif.monitor_cb.rdata;
        trans_collected.error_type = vif.monitor_cb.error      ? ERROR      :
                                     vif.monitor_cb.align_error ? ALIGN_ERROR :
                                                                   NO_ERROR;
        item_collected_port.write(trans_collected);
      end

      //-------------------------------------------------------------------
      // Detect BURST_WRITE
      //-------------------------------------------------------------------
      else if (vif.monitor_cb.burst_wr === 1'b1) begin
        trans_collected = soc_seq_item::type_id::create("trans_collected");
        trans_collected.op_type   = BURST_WRITE;
        trans_collected.addr      = vif.monitor_cb.addr;
        trans_collected.burst_len = vif.monitor_cb.burst_len;
        trans_collected.data      = vif.monitor_cb.wdata;
        trans_collected.error_type = NO_ERROR;
        // Wait out burst beats
        repeat (trans_collected.burst_len) @(posedge vif.MONITOR.clk);
        item_collected_port.write(trans_collected);
      end

      //-------------------------------------------------------------------
      // Detect BURST_READ
      //-------------------------------------------------------------------
      else if (vif.monitor_cb.burst_rd === 1'b1) begin
        trans_collected = soc_seq_item::type_id::create("trans_collected");
        trans_collected.op_type   = BURST_READ;
        trans_collected.addr      = vif.monitor_cb.addr;
        trans_collected.burst_len = vif.monitor_cb.burst_len;
        repeat (trans_collected.burst_len) @(posedge vif.MONITOR.clk);
        trans_collected.rdata      = vif.monitor_cb.rdata;
        trans_collected.error_type = NO_ERROR;
        item_collected_port.write(trans_collected);
      end

    end
  endtask : run_phase

endclass : soc_monitor
