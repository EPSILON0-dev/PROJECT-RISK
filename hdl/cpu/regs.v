`include "config.v"

module regs (
  input         i_clk,
  input         i_ce,

  input  [ 4:0] i_addr_rd_a,
  input  [ 4:0] i_addr_rd_b,

  input         i_we,
  input  [ 4:0] i_addr_wr,
  input  [31:0] i_dat_wr,

  output [31:0] o_dat_rd_a,
  output [31:0] o_dat_rd_b
);

  // Register array
`ifdef HARDWARE_TIPS
`ifdef REGS_DISTRIBUTED
  (* ram_style = "distributed" *)
`else
  (* ram_style = "block" *)
`endif
`endif
  reg [31:0] registers [0:31];
  reg [31:0] dat_rd_a_reg = 0;
  reg [31:0] dat_rd_b_reg = 0;

  // Register array initialization (filling with zeros), this is required for
  //  the simulation to eliminate undefined values at the start
`ifndef HARDWARE_TIPS
  initial begin
    for (integer i = 0; i < 32; i=i+1) begin
      registers[i] = 32'd0;
    end
  end
`endif

  // Register read/write process
  always @(posedge i_clk) begin
    dat_rd_a_reg <= registers[i_addr_rd_a];
    dat_rd_b_reg <= registers[i_addr_rd_b];

    if (i_ce && i_we && (i_addr_wr != 5'b00000)) begin
      registers[i_addr_wr] <= i_dat_wr;
    end
  end

  /**
   * Output assgnment
   */
  assign o_dat_rd_a = dat_rd_a_reg;
  assign o_dat_rd_b = dat_rd_b_reg;

endmodule
