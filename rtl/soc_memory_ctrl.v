//=============================================================================
// soc_memory_ctrl.v — SoC Memory Controller DUT (RTL Stub)
// Data: 32-bit | Address: 10-bit (256 × 32-bit words = 1KB)
// Ops:  READ, WRITE, BURST_READ, BURST_WRITE
// Errors: out-of-range address → error, unaligned → align_error
// Reset: active HIGH synchronous
//=============================================================================

module soc_memory_ctrl (
  input  wire        clk,
  input  wire        reset,

  // Control
  input  wire        wr_en,
  input  wire        rd_en,
  input  wire        burst_wr,
  input  wire        burst_rd,
  input  wire [3:0]  burst_len,   // 1–16 beats
  input  wire [9:0]  addr,

  // Data
  input  wire [31:0] wdata,
  output reg  [31:0] rdata,

  // Status
  output reg         valid,
  output reg         error,
  output reg         align_error
);

  //-----------------------------------------------------------------------
  // Internal memory: 256 × 32-bit words (1 KB)
  //-----------------------------------------------------------------------
  reg [31:0] mem [0:255];

  integer i;

  always @(posedge clk) begin
    if (reset) begin
      rdata       <= 32'h0;
      valid       <= 1'b0;
      error       <= 1'b0;
      align_error <= 1'b0;
    end else begin
      // Default de-assert
      valid       <= 1'b0;
      error       <= 1'b0;
      align_error <= 1'b0;
      rdata       <= 32'h0;

      //---------------------------------------------------------------------
      // WRITE
      //---------------------------------------------------------------------
      if (wr_en) begin
        if (addr > 10'h3FF) begin
          error <= 1'b1;
        end else if (addr[1:0] != 2'b00) begin
          align_error <= 1'b1;
        end else begin
          mem[addr[9:2]] <= wdata;
          valid          <= 1'b1;
        end
      end

      //---------------------------------------------------------------------
      // READ
      //---------------------------------------------------------------------
      else if (rd_en) begin
        if (addr > 10'h3FF) begin
          error <= 1'b1;
        end else if (addr[1:0] != 2'b00) begin
          align_error <= 1'b1;
        end else begin
          rdata <= mem[addr[9:2]];
          valid <= 1'b1;
        end
      end

      //---------------------------------------------------------------------
      // BURST WRITE (simplified: same wdata written to consecutive addresses)
      //---------------------------------------------------------------------
      else if (burst_wr) begin
        for (i = 0; i < burst_len; i = i + 1) begin
          if ((addr + i) <= 10'h3FF)
            mem[(addr[9:2]) + i] <= wdata;
        end
        valid <= 1'b1;
      end

      //---------------------------------------------------------------------
      // BURST READ (simplified: return data at base address)
      //---------------------------------------------------------------------
      else if (burst_rd) begin
        rdata <= mem[addr[9:2]];
        valid <= 1'b1;
      end

    end
  end

endmodule : soc_memory_ctrl
