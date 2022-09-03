`include "config.v"

module hazard (
  input         i_hz_rs1,
  input         i_hz_rs2,

  input   [4:0] i_rs1,
  input   [4:0] i_rs2,

  input   [4:0] i_ex_wb_reg,
  input   [4:0] i_ma_wb_reg,
  input   [4:0] i_wb_wb_reg,

  // verilator lint_off unused

  input         i_ex_wb_en,
  input         i_ma_wb_en,
  input         i_wb_wb_en,

  input   [1:0] i_ex_wb_mux,
  input   [1:0] i_ma_wb_mux,

  input  [31:0] i_ex_res_dat,
  input  [31:0] i_ex_ret,
  input  [31:0] i_ma_rd_dat,
  input  [31:0] i_ma_res,
  input  [31:0] i_ma_ret,
  input  [31:0] i_wb_wb_d,

  // verilator lint_on unused

  input  [31:0] i_rs1_raw_d,
  input  [31:0] i_rs2_raw_d,

  output [31:0] o_rs1_d,
  output [31:0] o_rs2_d,

  output        o_hz_data
);

`ifdef HAZARD_DATA_FORWARDNG
  ///////////////////////////////////////////////////////////////////////////
  // If hazard data forwarding is enabled hazard unit tries to forward the
  //  data from the pipeline, if it cannot be done data hazard is generated
  ///////////////////////////////////////////////////////////////////////////

  // Hazard enables for read registers
  wire rs1_hz_en = i_hz_rs1 && |i_rs1;
  wire rs2_hz_en = i_hz_rs2 && |i_rs2;

  // Hazards at write back phase
  wire hz_wb1 = rs1_hz_en && (i_rs1 == i_wb_wb_reg) && i_wb_wb_en;
  wire hz_wb2 = rs2_hz_en && (i_rs2 == i_wb_wb_reg) && i_wb_wb_en;

  // Hazards at memory access phase
  wire hz_ma1     = rs1_hz_en && (i_rs1 == i_ma_wb_reg) && i_ma_wb_en;
  wire hz_ma2     = rs2_hz_en && (i_rs2 == i_ma_wb_reg) && i_ma_wb_en;
  wire hz_ma_res1 = hz_ma1 && (i_ma_wb_mux == 2'b00);
  wire hz_ma_ret1 = hz_ma1 && (i_ma_wb_mux == 2'b10);
  wire hz_ma_rd1  = hz_ma1 && (i_ma_wb_mux == 2'b01);
  wire hz_ma_res2 = hz_ma2 && (i_ma_wb_mux == 2'b00);
  wire hz_ma_ret2 = hz_ma2 && (i_ma_wb_mux == 2'b10);
  wire hz_ma_rd2  = hz_ma2 && (i_ma_wb_mux == 2'b01);

  // Hazards at execute phase
  wire hz_ex1     = rs1_hz_en && (i_rs1 == i_ex_wb_reg) && i_ex_wb_en;
  wire hz_ex2     = rs2_hz_en && (i_rs2 == i_ex_wb_reg) && i_ex_wb_en;
  wire hz_ex_res1 = hz_ex1 && (i_ex_wb_mux == 2'b00);
  wire hz_ex_ret1 = hz_ex1 && (i_ex_wb_mux == 2'b10);
  wire hz_ex_rd1  = hz_ex1 && (i_ex_wb_mux == 2'b01);
  wire hz_ex_res2 = hz_ex2 && (i_ex_wb_mux == 2'b00);
  wire hz_ex_ret2 = hz_ex2 && (i_ex_wb_mux == 2'b10);
  wire hz_ex_rd2  = hz_ex2 && (i_ex_wb_mux == 2'b01);

  // Forwarding to rs1
  wire [31:0] rs1_d =
    (hz_wb1)     ? i_wb_wb_d :
    (hz_ma_res1) ? i_ma_res :
    (hz_ma_ret1) ? i_ma_ret :
    (hz_ma_rd1)  ? i_ma_rd_dat :
    (hz_ex_ret1) ? i_ex_ret :
    i_rs1_raw_d;

  // Forwarding to rs2
  wire [31:0] rs2_d =
    (hz_wb2)     ? i_wb_wb_d :
    (hz_ma_res2) ? i_ma_res :
    (hz_ma_ret2) ? i_ma_ret :
    (hz_ma_rd2)  ? i_ma_rd_dat :
    (hz_ex_ret2) ? i_ex_ret :
    i_rs2_raw_d;

  // Critical unrecoverable hazards
  wire hz_data = hz_ex_rd1 || hz_ex_rd2 || hz_ex_res1 || hz_ex_res2;

`else
  ///////////////////////////////////////////////////////////////////////////
  // This version of hazard unit is like a crying baby that cannot do
  //  anything on it's own and cries "data hazard" every time something
  //  goes at least slightly wrong
  ///////////////////////////////////////////////////////////////////////////
  wire hz_dat_rs1 = i_hz_rs1 && (i_rs1 != 0) && ((i_rs1 == i_ex_wb_reg)
    || (i_rs1 == i_ma_wb_reg) || (i_rs1 == i_wb_wb_reg));
  wire hz_dat_rs2 = i_hz_rs2 && (i_rs2 != 0) && ((i_rs2 == i_ex_wb_reg)
    || (i_rs2 == i_ma_wb_reg) || (i_rs2 == i_wb_wb_reg));
  wire hz_data = hz_dat_rs1 || hz_dat_rs2;

  // Pass through for registers direcly, they won't be used on hazard anyway
  wire [31:0] rs1_d = i_rs1_raw_d;
  wire [31:0] rs2_d = i_rs2_raw_d;
`endif

  assign o_rs1_d = rs1_d;
  assign o_rs2_d = rs2_d;
  assign o_hz_data = hz_data;

endmodule

