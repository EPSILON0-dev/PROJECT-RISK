`include "config.v"
`include "shifter.v"

`ifdef M_EXTENSION
`include "muldiv.v"
`endif

module alu (
  input         i_clk_n,
  // verilator lint_off unused
  input         i_rst,
  // verilator lint_on unused

  input  [31:0] i_in_a,
  input  [31:0] i_in_b,

  input  [ 2:0] i_funct3,
  input  [ 6:0] i_funct7,
  input         i_alu_en,
  input         i_alu_imm,

  output        o_busy,
  output [31:0] o_alu_out
);


  // Funct7 decoding
  wire        funct7_5;

  // Adder/subtractor
  wire        op_subtract;
  wire [31:0] adder_in_b;
  wire [31:0] adder_out;

  // Logic operations
  wire [31:0] logic_xor;
  wire [31:0] logic_or;
  wire [31:0] logic_and;

  // Comparators
  wire [31:0] comp;
  wire [31:0] comp_u;

  // Shifter
  wire [31:0] shift_result;
  wire        shift_en;
  wire        shift_busy;

  // Final MUX
  reg  [31:0] mux;

  // M extension circuitry
`ifdef M_EXTENSION
  wire        funct7_0;
  wire [31:0] md_result;
  wire        md_en;
  wire        md_busy;
`endif


  /**
   * Funct7 decoding
   *  funct7_5 is alternative ALU operation
   *  funct7_0 is M extension operation
   */
  assign funct7_5 = (i_funct7 == 7'b0100000);
`ifdef M_EXTENSION
  assign funct7_0 = (i_funct7 == 7'b0000001);
`endif

  /**
   * Adder/subtractor
   */
  assign op_subtract = i_alu_en && !i_alu_imm && funct7_5;
  assign adder_in_b = (op_subtract) ? ~i_in_b : i_in_b;
  assign adder_out = i_in_a + adder_in_b + {31'd0, op_subtract};

  /**
   * Logic operators
   */
  assign logic_xor = i_in_a ^ i_in_b;
  assign logic_or  = i_in_a | i_in_b;
  assign logic_and = i_in_a & i_in_b;

  /**
   * Signed/unsigned comparator
   *  comp is signed comparison result
   *  comp_u is unsigned comparison result
   *  comparison results are zero-extended to 32 bits to fit final MUX
   */
  assign comp   = {31'd0, (  $signed(i_in_a) <   $signed(i_in_b))};
  assign comp_u = {31'd0, ($unsigned(i_in_a) < $unsigned(i_in_b))};

  /**
   * Shifter circuitry
   */
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
  assign shift_en = i_alu_en && !md_en;
`else
  assign shift_en = i_alu_en;
`endif

  /**
   * Final ALU MUX
   */
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

  /**
   * M extension circuitry
   */
`ifdef M_EXTENSION
  muldiv muldiv_i (
    .i_clk_n   (i_clk_n),
    .i_rst     (i_rst),
    .i_in_a    (i_in_a),
    .i_in_b    (i_in_b),
    .i_funct3  (i_funct3),
    .i_md_en   (md_en),
    .o_result  (md_result),
    .o_busy    (md_busy)
  );

  assign md_en = funct7_0 && i_alu_en && !i_alu_imm;
`endif

  /**
   * Output assignment
   *  Here ALU MUX output and M extension output is combined
   */
`ifdef M_EXTENSION
  assign o_busy = shift_busy || md_busy;
  assign o_alu_out = (md_en) ? md_result : mux;
`else
  assign o_busy = shift_busy;
  assign o_alu_out = mux;
`endif

endmodule
