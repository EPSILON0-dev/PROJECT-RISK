`include "config.v"

module regs (
  input         i_clk,
  input         i_ce,

  input  [ 4:0] i_addr_rd_a,
  input  [ 4:0] i_addr_rd_b,

  input         i_we,
  input  [ 4:0] i_addr_wr,
  input  [31:0] i_dat_wr,

  input         i_hz_rs1,
  input         i_hz_rs2,
  input   [4:0] i_ex_wb_reg,
  input   [4:0] i_ma_wb_reg,

  output        o_hz_data,
  output [31:0] o_dat_rd_a,
  output [31:0] o_dat_rd_b);


  /**
   * Register array
   */
  reg [31:0] registers [0:31];
  reg [31:0] dat_rd_a_reg = 0;
  reg [31:0] dat_rd_b_reg = 0;

  // Register array initialization (filling with zeros), this is required for
  //  the simulation to eliminate undefined values at the start
  initial begin
    for (integer i = 0; i < 32; i=i+1) begin
      registers[i] = 32'd0;
    end
  end

  // Register read/write process
  always @(posedge i_clk) begin
    dat_rd_a_reg <= registers[i_addr_rd_a];
    dat_rd_b_reg <= registers[i_addr_rd_b];

    if (i_ce && i_we && (i_addr_wr != 5'b00000)) begin
      registers[i_addr_wr] <= i_dat_wr;
    end
  end

  ///////////////////////////////////////////////////////////////////////////
  // If REGS_PASS_THROUGH is enabled we either put read data on read lines or
  //  we pass write data through in case of hazard
  ///////////////////////////////////////////////////////////////////////////
`ifdef REGS_PASS_THROUGH
  wire [31:0] dat_rd_a = (write_pass_a_en) ? i_dat_wr : dat_rd_a_reg;
  wire [31:0] dat_rd_b = (write_pass_b_en) ? i_dat_wr : dat_rd_b_reg;

  wire write_pass_a_en = i_addr_rd_a == i_addr_wr && write_pass_en;
  wire write_pass_b_en = i_addr_rd_b == i_addr_wr && write_pass_en;
  wire write_pass_en = i_addr_wr != 5'b00000 && i_we;

  ///////////////////////////////////////////////////////////////////////////
  // If REGS_PASS_THROUGH is disabled we just assign read data to read lines
  ///////////////////////////////////////////////////////////////////////////
`else
  wire [31:0] dat_rd_a = dat_rd_a_reg;
  wire [31:0] dat_rd_b = dat_rd_b_reg;
`endif

  ///////////////////////////////////////////////////////////////////////////
  // If REGS_PASS_THROUGH is enabled hazard detector only checks for hazard
  //  on execute and memory access phase as it can forward data from write
  //  back phase.
  ///////////////////////////////////////////////////////////////////////////
  wire [4:0] rs1 = i_addr_rd_a;
  wire [4:0] rs2 = i_addr_rd_b;
  wire [4:0] wb_wb_reg = i_addr_wr;
`ifdef REGS_PASS_THROUGH
  wire hz_dat_rs1 = i_hz_rs1 && (rs1 != 5'b0000) &&
    ((rs1 == i_ex_wb_reg) || (rs1 == i_ma_wb_reg));
  wire hz_dat_rs2 = i_hz_rs2 && (rs2 != 5'b0000) &&
    ((rs2 == i_ex_wb_reg) || (rs2 == i_ma_wb_reg));
  //
  ///////////////////////////////////////////////////////////////////////////
  // If REGS_PASS_THROUGH is disabled hazard detector checks for hazard on
  //  all execution phases as it cannot forward any data
  ///////////////////////////////////////////////////////////////////////////
`else
  wire hz_dat_rs1 = i_hz_rs1 && (rs1 != 5'b0000) &&
    ((rs1 == i_ex_wb_reg) || (rs1 == i_ma_wb_reg) || (rs1 == wb_wb_reg));
  wire hz_dat_rs2 = i_hz_rs2 && (rs2 != 5'b0000) &&
    ((rs2 == i_ex_wb_reg) || (rs2 == i_ma_wb_reg) || (rs2 == wb_wb_reg));
`endif

  wire hz_data = hz_dat_rs1 || hz_dat_rs2;


  /**
   * Output assgnment
   */

  assign o_hz_data = hz_data;
  assign o_dat_rd_a = dat_rd_a;
  assign o_dat_rd_b = dat_rd_b;

endmodule
