`include "../config.v"
`include "shifter.v"

`ifdef MULDIV_EXTENSION
`include "muldiv.v"
`endif

module alu (
  input         i_clk_n,

  input  [31:0] i_in_a,
  input  [31:0] i_in_b,

  input  [ 2:0] i_funct3,
  input  [ 6:0] i_funct7,
  input         i_alu_en,
  input         i_alu_imm,

  output        o_busy,
  output [31:0] o_alu_out
);


  ///////////////////////////////////////////////////////////////////////////
  // Funct7 decoding
  ///////////////////////////////////////////////////////////////////////////
  wire funct7_5 = (i_funct7 == 7'b0100000);

`ifdef MULDIV_EXTENSION
  wire funct7_0 = (i_funct7 == 7'b0000001);
`endif


  ///////////////////////////////////////////////////////////////////////////
  // Adder/subtractor
  ///////////////////////////////////////////////////////////////////////////
  wire op_subtract = i_alu_en && !i_alu_imm && funct7_5;
  wire [31:0] adder_in_b = (op_subtract) ? ~i_in_b : i_in_b;
  wire [31:0] adder_out = i_in_a + adder_in_b + {31'd0, op_subtract};


  ///////////////////////////////////////////////////////////////////////////
  // Logic operators
  ///////////////////////////////////////////////////////////////////////////
  wire [31:0] logic_xor = i_in_a ^ i_in_b;
  wire [31:0] logic_or  = i_in_a | i_in_b;
  wire [31:0] logic_and = i_in_a & i_in_b;


  ///////////////////////////////////////////////////////////////////////////
  // Signed/unsigned comparator
  ///////////////////////////////////////////////////////////////////////////
  wire [31:0] comp   = {31'd0, (  $signed(i_in_a) <   $signed(i_in_b))};
  wire [31:0] comp_u = {31'd0, ($unsigned(i_in_a) < $unsigned(i_in_b))};


  ///////////////////////////////////////////////////////////////////////////
  // Shifter
  ///////////////////////////////////////////////////////////////////////////
  wire [31:0] shift_result;
  wire        shift_busy;

  shifter shifter_i (
    .i_clk_n    (i_clk_n),
    .i_in_a     (i_in_a),
    .i_in_b     (i_in_b[4:0]),
    .i_funct3   (i_funct3),
    .i_funct7_5 (funct7_5),
    .i_alu_en   (i_alu_en),
    .o_result   (shift_result),
    .o_busy     (shift_busy)
  );


  ///////////////////////////////////////////////////////////////////////////
  // Final alu mux
  ///////////////////////////////////////////////////////////////////////////
  wire [31:0] mux_01 = (i_funct3[0] && i_alu_en) ? shift_result : adder_out;
  wire [31:0] mux_23 = (i_funct3[0] && i_alu_en) ? comp_u       : comp;
  wire [31:0] mux_45 = (i_funct3[0] && i_alu_en) ? shift_result : logic_xor;
  wire [31:0] mux_67 = (i_funct3[0] && i_alu_en) ? logic_and    : logic_or;

  wire [31:0] mux_03 = (i_funct3[1] && i_alu_en) ? mux_23 : mux_01;
  wire [31:0] mux_47 = (i_funct3[1] && i_alu_en) ? mux_67 : mux_45;

  wire [31:0] mux_07 = (i_funct3[2] && i_alu_en) ? mux_47 : mux_03;


`ifdef MULDIV_EXTENSION

  ///////////////////////////////////////////////////////////////////////////
  // Multiplier and divider
  ///////////////////////////////////////////////////////////////////////////
  wire [31:0] md_result;
  wire        md_enable;
  wire        md_busy;

  muldiv muldiv_i (
    .i_clk_n    (i_clk_n),
    .i_in_a     (i_in_a),
    .i_in_b     (i_in_b),
    .i_funct3   (i_funct3),
    .i_funct7_0 (funct7_0),
    .i_alu_en   (i_alu_en),
    .i_alu_imm  (i_alu_imm),
    .o_result   (md_result),
    .o_enable   (md_enable),
    .o_busy     (md_busy)
  );

`endif


  ///////////////////////////////////////////////////////////////////////////
  // Output assignment
  ///////////////////////////////////////////////////////////////////////////

`ifdef MULDIV_EXTENSION
  assign o_busy = shift_busy || md_busy;
  assign o_alu_out = (md_enable) ? md_result : mux_07;
`else
  assign o_busy = shift_busy;
  assign o_alu_out = mux_07;
`endif


endmodule
