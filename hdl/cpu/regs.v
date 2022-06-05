`include "config.v"

module regs (
  input         i_clk,

  input  [ 4:0] i_addr_rd_a,
  input  [ 4:0] i_addr_rd_b,

  input         i_we,
  input  [ 4:0] i_addr_wr,
  input  [31:0] i_dat_wr,

  output [31:0] o_dat_rd_a,
  output [31:0] o_dat_rd_b);


  ///////////////////////////////////////////////////////////////////////////
  // Register array
  ///////////////////////////////////////////////////////////////////////////
  reg [31:0] registers [0:31];
  reg [31:0] dat_rd_a;
  reg [31:0] dat_rd_b;

  initial begin
    for (integer i = 0; i < 32; i=i+1) begin
      registers[i] = 32'd0;
    end
  end

  // verilator lint_off BLKSEQ
  always @(posedge i_clk) begin
    if (i_we && (i_addr_wr != 5'b00000)) begin
      registers[i_addr_wr] <= i_dat_wr;
    end

    dat_rd_a <= registers[i_addr_rd_a];
    dat_rd_b <= registers[i_addr_rd_b];

`ifdef REGS_PASS_THROUGH
    if (i_addr_rd_a == i_addr_wr && i_addr_wr != 5'b00000 && i_we) begin
      dat_rd_a <= i_dat_wr;
    end
    if (i_addr_rd_b == i_addr_wr && i_addr_wr != 5'b00000 && i_we) begin
      dat_rd_b <= i_dat_wr;
    end
`endif

  end
  // verilator lint_on BLKSEQ


  ///////////////////////////////////////////////////////////////////////////
  // Output assgnment
  ///////////////////////////////////////////////////////////////////////////
  assign o_dat_rd_a = dat_rd_a;
  assign o_dat_rd_b = dat_rd_b;

endmodule
