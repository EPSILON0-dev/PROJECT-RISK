/****************************************************************************
 * Copyright 2022 Lukasz Forenc
 *
 * File: regs.v
 *
 * Simple register array, there's an option to generate it as a distributed
 * RAM array. The array has one write port and two read ports, when the write
 * address is zero write is disabled (zero isn't hard-wired but works anyway).
 *
 * i_clk       - Clock input
 * i_ce        - Clock enable input
 * i_addr_rd_a - Read address 1 (RS1)
 * i_addr_rd_b - Read address 2 (RS2)
 * i_we        - Write enable input
 * i_addr_wr   - Write address (RD)
 * i_data_wr   - Write data (RD)
 *
 * o_dat_rd_a  - Read data 1 (RS1)
 * o_dat_rd_b  - Read data 2 (RS2)
 ***************************************************************************/
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
