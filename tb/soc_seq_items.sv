//=============================================================================
// soc_seq_item.sv — Transaction Item for soc_memory_ctrl
//=============================================================================

//=============================================================================
// soc_seq_item.sv — Transaction Item for soc_memory_ctrl
//=============================================================================

typedef enum logic [2:0] {
  WRITE       = 3'b000,
  READ        = 3'b001,
  BURST_WRITE = 3'b010,
  BURST_READ  = 3'b011,
  RESET       = 3'b100,
  IDLE        = 3'b101
} op_type_e;

typedef enum logic [1:0] {
  NO_ERROR    = 2'b00,
  ERROR       = 2'b01,
  ALIGN_ERROR = 2'b10
} error_type_e;

class soc_seq_item extends uvm_sequence_item;

  //-----------------------------------------------------------------------
  // 1. Declare All Fields First
  //-----------------------------------------------------------------------
  rand op_type_e    op_type;
  rand logic [9:0]  addr;
  rand logic [31:0] data;
  rand logic [3:0]  burst_len; // 1–16

  // Response fields — captured by monitor
  logic [31:0]  rdata;
  error_type_e  error_type;

  //-----------------------------------------------------------------------
  // 2. Run UVM Automation Macros After Field Declarations
  //-----------------------------------------------------------------------
  `uvm_object_utils_begin(soc_seq_item)
    `uvm_field_enum(op_type_e,   op_type,   UVM_ALL_ON)
    `uvm_field_int (addr,                   UVM_ALL_ON)
    `uvm_field_int (data,                   UVM_ALL_ON)
    `uvm_field_int (burst_len,              UVM_ALL_ON)
    `uvm_field_int (rdata,                  UVM_ALL_ON)
    `uvm_field_enum(error_type_e, error_type, UVM_ALL_ON)
  `uvm_object_utils_end

  //-----------------------------------------------------------------------
  // Constraints
  //-----------------------------------------------------------------------
  // Burst length valid range: 1 to 16
  constraint c_burst_len {
    burst_len inside {[1:16]};
  }

  // Burst length > 1 only for burst operations
  constraint c_burst_op {
    if (op_type inside {WRITE, READ, RESET, IDLE})
      burst_len == 1;
  }

  // Keep address in-range by default (out-of-range tested separately)
  constraint c_addr_in_range {
    addr inside {[10'h000 : 10'h3FF]};
  }

  //-----------------------------------------------------------------------
  // Constructor
  //-----------------------------------------------------------------------
  function new(string name = "soc_seq_item");
    super.new(name);
  endfunction : new

endclass : soc_seq_item
