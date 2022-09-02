`include "config.v"

module hazard (
  input        i_hz_rs1,
  input        i_hz_rs2,
  input  [4:0] i_rs1,
  input  [4:0] i_rs2,
  input  [4:0] i_ex_wb_reg,
  input  [4:0] i_ma_wb_reg,
  // verilator lint_off unused
  input  [4:0] i_wb_wb_reg,
  // verilator lint_on unused

  output       o_hz_data
);

`ifdef REGS_PASS_THROUGH
  wire hz_dat_rs1 = i_hz_rs1 && (i_rs1 != 5'b0000) &&
    ((i_rs1 == i_ex_wb_reg) || (i_rs1 == i_ma_wb_reg));
  wire hz_dat_rs2 = i_hz_rs2 && (i_rs2 != 5'b0000) &&
    ((i_rs2 == i_ex_wb_reg) || (i_rs2 == i_ma_wb_reg));
`else
  wire hz_dat_rs1 = i_hz_rs1 && (i_rs1 != 5'b0000) &&
    ((i_rs1 == i_ex_wb_reg) || (i_rs1 == i_ma_wb_reg) || (i_rs1 == i_wb_wb_reg));
  wire hz_dat_rs2 = i_hz_rs2 && (i_rs2 != 5'b0000) &&
    ((i_rs2 == i_ex_wb_reg) || (i_rs2 == i_ma_wb_reg) || (i_rs2 == i_wb_wb_reg));
`endif

  wire hz_data = hz_dat_rs1 || hz_dat_rs2;

  assign o_hz_data = hz_data;

endmodule
