//=============================================================================
// soc_sequences.sv — Test Sequences for soc_memory_ctrl
// Sequences: directed, burst, corner, random, regression
//=============================================================================

//-----------------------------------------------------------------------------
// Base sequence — sends N constrained-random transactions
//-----------------------------------------------------------------------------
class soc_base_sequence extends uvm_sequence #(soc_seq_item);

  `uvm_object_utils(soc_base_sequence)

  int unsigned num_trans = 10;

  function new(string name = "soc_base_sequence");
    super.new(name);
  endfunction : new

  task body();
    soc_seq_item req;
    repeat (num_trans) begin
      req = soc_seq_item::type_id::create("req");
      wait_for_grant();
      assert(req.randomize());
      send_request(req);
      wait_for_item_done();
    end
  endtask : body

endclass : soc_base_sequence

//-----------------------------------------------------------------------------
// directed_seq — basic WRITE then READ at the same address
//-----------------------------------------------------------------------------
class directed_seq extends uvm_sequence #(soc_seq_item);

  `uvm_object_utils(directed_seq)

  function new(string name = "directed_seq");
    super.new(name);
  endfunction : new

  task body();
    soc_seq_item req;

    // WRITE 0xDEADBEEF to 0x000
    `uvm_do_with(req, { op_type == WRITE; addr == 10'h000; data == 32'hDEADBEEF; })
    // READ back from 0x000
    `uvm_do_with(req, { op_type == READ;  addr == 10'h000; })

    // WRITE 0xCAFEBABE to 0x004
    `uvm_do_with(req, { op_type == WRITE; addr == 10'h004; data == 32'hCAFEBABE; })
    `uvm_do_with(req, { op_type == READ;  addr == 10'h004; })

    // WRITE 0x12345678 to 0x008
    `uvm_do_with(req, { op_type == WRITE; addr == 10'h008; data == 32'h12345678; })
    `uvm_do_with(req, { op_type == READ;  addr == 10'h008; })
  endtask : body

endclass : directed_seq

//-----------------------------------------------------------------------------
// burst_seq — BURST_WRITE then BURST_READ (closes burst_write/read bins)
//-----------------------------------------------------------------------------
class burst_seq extends uvm_sequence #(soc_seq_item);

  `uvm_object_utils(burst_seq)

  function new(string name = "burst_seq");
    super.new(name);
  endfunction : new

  task body();
    soc_seq_item req;

    // Short burst (2-4)
    `uvm_do_with(req, { op_type == BURST_WRITE; addr == 10'h100;
                         burst_len inside {[2:4]}; })
    `uvm_do_with(req, { op_type == BURST_READ;  addr == 10'h100;
                         burst_len inside {[2:4]}; })

    // Medium burst (5-8)
    `uvm_do_with(req, { op_type == BURST_WRITE; addr == 10'h110;
                         burst_len inside {[5:8]}; })
    `uvm_do_with(req, { op_type == BURST_READ;  addr == 10'h110;
                         burst_len inside {[5:8]}; })

    // Long burst (9-16)
    `uvm_do_with(req, { op_type == BURST_WRITE; addr == 10'h120;
                         burst_len inside {[9:16]}; })
    `uvm_do_with(req, { op_type == BURST_READ;  addr == 10'h120;
                         burst_len inside {[9:16]}; })
  endtask : body

endclass : burst_seq

//-----------------------------------------------------------------------------
// high_addr_seq — hits zone2 (0x200-0x2FF) and zone3 (0x300-0x3FF)
//-----------------------------------------------------------------------------
class high_addr_seq extends uvm_sequence #(soc_seq_item);

  `uvm_object_utils(high_addr_seq)

  function new(string name = "high_addr_seq");
    super.new(name);
  endfunction : new

  task body();
    soc_seq_item req;

    // Zone 2: addr[9:8] == 2'b10
    `uvm_do_with(req, { op_type == WRITE; addr[9:8] == 2'b10; data == 32'hA5A5A5A5; })
    `uvm_do_with(req, { op_type == READ;  addr[9:8] == 2'b10; })

    // Zone 3: addr[9:8] == 2'b11
    `uvm_do_with(req, { op_type == WRITE; addr[9:8] == 2'b11; data == 32'h5A5A5A5A; })
    `uvm_do_with(req, { op_type == READ;  addr[9:8] == 2'b11; })
  endtask : body

endclass : high_addr_seq

//-----------------------------------------------------------------------------
// corner_seq — data pattern coverage: all_zeros, all_ones, walking_one
//              + RESET + IDLE + out-of-range ERROR
//-----------------------------------------------------------------------------
class corner_seq extends uvm_sequence #(soc_seq_item);

  `uvm_object_utils(corner_seq)

  function new(string name = "corner_seq");
    super.new(name);
  endfunction : new

  task body();
    soc_seq_item req;

    // All-zeros data pattern
    `uvm_do_with(req, { op_type == WRITE; addr == 10'h010; data == 32'h00000000; })
    `uvm_do_with(req, { op_type == READ;  addr == 10'h010; })

    // All-ones data pattern
    `uvm_do_with(req, { op_type == WRITE; addr == 10'h014; data == 32'hFFFFFFFF; })
    `uvm_do_with(req, { op_type == READ;  addr == 10'h014; })

    // Walking-one data patterns
    `uvm_do_with(req, { op_type == WRITE; addr == 10'h018; data == 32'h00000001; })
    `uvm_do_with(req, { op_type == WRITE; addr == 10'h01C; data == 32'h00000002; })
    `uvm_do_with(req, { op_type == WRITE; addr == 10'h020; data == 32'h00000004; })
    `uvm_do_with(req, { op_type == WRITE; addr == 10'h024; data == 32'h00000008; })

    // RESET operation
    `uvm_do_with(req, { op_type == RESET; })

    // IDLE operation
    `uvm_do_with(req, { op_type == IDLE; })

  endtask : body

endclass : corner_seq

//-----------------------------------------------------------------------------
// cross_coverage_seq — hits all 8 cross bins (READ+WRITE × zone0-3)
//-----------------------------------------------------------------------------
class cross_coverage_seq extends uvm_sequence #(soc_seq_item);

  `uvm_object_utils(cross_coverage_seq)

  function new(string name = "cross_coverage_seq");
    super.new(name);
  endfunction : new

  task body();
    soc_seq_item req;

    // WRITE to all 4 zones
    `uvm_do_with(req, { op_type == WRITE; addr[9:8] == 2'b00; data == 32'hAABBCCDD; })
    `uvm_do_with(req, { op_type == WRITE; addr[9:8] == 2'b01; data == 32'h11223344; })
    `uvm_do_with(req, { op_type == WRITE; addr[9:8] == 2'b10; data == 32'h55667788; })
    `uvm_do_with(req, { op_type == WRITE; addr[9:8] == 2'b11; data == 32'h99AABBCC; })

    // READ from all 4 zones
    `uvm_do_with(req, { op_type == READ; addr[9:8] == 2'b00; })
    `uvm_do_with(req, { op_type == READ; addr[9:8] == 2'b01; })
    `uvm_do_with(req, { op_type == READ; addr[9:8] == 2'b10; })
    `uvm_do_with(req, { op_type == READ; addr[9:8] == 2'b11; })
  endtask : body

endclass : cross_coverage_seq

//-----------------------------------------------------------------------------
// random_seq — constrained-random transactions
//-----------------------------------------------------------------------------
class random_seq extends uvm_sequence #(soc_seq_item);

  `uvm_object_utils(random_seq)
  int unsigned num_trans = 20;

  function new(string name = "random_seq");
    super.new(name);
  endfunction : new

  task body();
    soc_seq_item req;
    repeat (num_trans) begin
      req = soc_seq_item::type_id::create("req");
      wait_for_grant();
      assert(req.randomize());
      send_request(req);
      wait_for_item_done();
    end
  endtask : body

endclass : random_seq

//-----------------------------------------------------------------------------
// regression_seq — runs all sub-sequences for full coverage closure
//-----------------------------------------------------------------------------
class regression_seq extends uvm_sequence #(soc_seq_item);

  `uvm_object_utils(regression_seq)

  directed_seq       dir_seq;
  burst_seq          bst_seq;
  high_addr_seq      hi_seq;
  corner_seq         cor_seq;
  cross_coverage_seq cx_seq;
  random_seq         rnd_seq;

  function new(string name = "regression_seq");
    super.new(name);
  endfunction : new

  task body();
    `uvm_do(dir_seq)
    `uvm_do(bst_seq)
    `uvm_do(hi_seq)
    `uvm_do(cor_seq)
    `uvm_do(cx_seq)
    `uvm_do(rnd_seq)
  endtask : body

endclass : regression_seq
