//=============================================================================
// soc_driver.sv — UVM Driver for soc_memory_ctrl
//=============================================================================

`define DRIV_IF vif.DRIVER.driver_cb

class soc_driver extends uvm_driver #(soc_seq_item);

  `uvm_component_utils(soc_driver)

  //-----------------------------------------------------------------------
  // Virtual interface handle
  //-----------------------------------------------------------------------
  virtual soc_if vif;

  //-----------------------------------------------------------------------
  // Constructor
  //-----------------------------------------------------------------------
  function new(string name = "soc_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //-----------------------------------------------------------------------
  // build_phase — retrieve virtual interface from config_db
  //-----------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual soc_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", {"Virtual interface must be set for: ", get_full_name()})
  endfunction : build_phase

  //-----------------------------------------------------------------------
  // run_phase — fetch seq_items and drive DUT
  //-----------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    soc_seq_item req;

    // Initial idle state
    `DRIV_IF.wr_en     <= 0;
    `DRIV_IF.rd_en     <= 0;
    `DRIV_IF.burst_wr  <= 0;
    `DRIV_IF.burst_rd  <= 0;
    `DRIV_IF.addr      <= 0;
    `DRIV_IF.wdata     <= 0;
    `DRIV_IF.burst_len <= 0;

    // Wait for reset de-assertion
    @(negedge vif.reset);
    @(posedge vif.clk);

    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      seq_item_port.item_done();
    end
  endtask : run_phase

  //-----------------------------------------------------------------------
  // drive() — apply one transaction to the DUT interface
  //-----------------------------------------------------------------------
  task drive(soc_seq_item req);
    // De-assert all controls first
    @(posedge vif.DRIVER.clk);
    `DRIV_IF.wr_en     <= 0;
    `DRIV_IF.rd_en     <= 0;
    `DRIV_IF.burst_wr  <= 0;
    `DRIV_IF.burst_rd  <= 0;

    case (req.op_type)
      //-------------------------------------------------------------------
      WRITE: begin
        @(posedge vif.DRIVER.clk);
        `DRIV_IF.wr_en <= 1;
        `DRIV_IF.addr  <= req.addr;
        `DRIV_IF.wdata <= req.data;
        @(posedge vif.DRIVER.clk);
        `DRIV_IF.wr_en <= 0;
      end
      //-------------------------------------------------------------------
      READ: begin
        @(posedge vif.DRIVER.clk);
        `DRIV_IF.rd_en <= 1;
        `DRIV_IF.addr  <= req.addr;
        @(posedge vif.DRIVER.clk);
        `DRIV_IF.rd_en <= 0;
      end
      //-------------------------------------------------------------------
      BURST_WRITE: begin
        `DRIV_IF.burst_wr  <= 1;
        `DRIV_IF.addr      <= req.addr;
        `DRIV_IF.burst_len <= req.burst_len;
        repeat (req.burst_len) begin
          @(posedge vif.DRIVER.clk);
          `DRIV_IF.wdata <= req.data;
        end
        @(posedge vif.DRIVER.clk);
        `DRIV_IF.burst_wr <= 0;
      end
      //-------------------------------------------------------------------
      BURST_READ: begin
        `DRIV_IF.burst_rd  <= 1;
        `DRIV_IF.addr      <= req.addr;
        `DRIV_IF.burst_len <= req.burst_len;
        repeat (req.burst_len) begin
          @(posedge vif.DRIVER.clk);
        end
        @(posedge vif.DRIVER.clk);
        `DRIV_IF.burst_rd <= 0;
      end
      //-------------------------------------------------------------------
      RESET: begin
        // Pulse the reset for 2 cycles
        @(posedge vif.DRIVER.clk);
        // reset is driven externally; just idle here
        repeat(2) @(posedge vif.DRIVER.clk);
      end
      //-------------------------------------------------------------------
      IDLE: begin
        repeat(3) @(posedge vif.DRIVER.clk);
      end
      //-------------------------------------------------------------------
      default: begin
        `uvm_warning("DRV", "Unknown op_type — skipping")
      end
    endcase

  endtask : drive

endclass : soc_driver
