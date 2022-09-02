`include "config.v"
`include "shifter.v"

`ifdef M_EXTENSION
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
`ifdef M_EXTENSION
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
    .i_op_alt   (funct7_5),
    .i_shift_en (shift_en),
    .o_result   (shift_result),
    .o_busy     (shift_busy)
  );

`ifdef M_EXTENSION
  wire shift_en = i_alu_en && !md_en;
`else
  wire shift_en = i_alu_en;
`endif


  ///////////////////////////////////////////////////////////////////////////
  // Final alu mux
  ///////////////////////////////////////////////////////////////////////////
  reg [31:0] mux;
  always @* begin
    case (i_funct3 & {3{i_alu_en}})
      3'b000: mux = adder_out;
      3'b001: mux = shift_result;
      3'b010: mux = comp;
      3'b011: mux = comp_u;
      3'b100: mux = logic_xor;
      3'b101: mux = shift_result;
      3'b110: mux = logic_or;
      3'b111: mux = logic_and;
    endcase
  end


  ///////////////////////////////////////////////////////////////////////////
  // Multiplier and divider
  ///////////////////////////////////////////////////////////////////////////
`ifdef M_EXTENSION
  wire [31:0] md_result;
  wire        md_busy;

  muldiv muldiv_i (
    .i_clk_n   (i_clk_n),
    .i_in_a    (i_in_a),
    .i_in_b    (i_in_b),
    .i_funct3  (i_funct3),
    .i_md_en   (md_en),
    .o_result  (md_result),
    .o_busy    (md_busy)
  );

  wire md_en = funct7_0 && i_alu_en && !i_alu_imm;

`endif


  ///////////////////////////////////////////////////////////////////////////
  // Output assignment
  ///////////////////////////////////////////////////////////////////////////
`ifdef M_EXTENSION
  assign o_busy = shift_busy || md_busy;
  assign o_alu_out = (md_en) ? md_result : mux;
`else
  assign o_busy = shift_busy;
  assign o_alu_out = mux;
`endif

endmodule
