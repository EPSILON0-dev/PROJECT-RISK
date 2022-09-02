module branch (
  input  [31:0] i_dat_a,
  input  [31:0] i_dat_b,

  input  [ 2:0] i_funct3,
  input  [ 4:0] i_opcode,

  output        o_br_en
);


  /**
   * Branch condition comparators
   */
  wire equal   = (i_dat_a == i_dat_b);
  wire lower   = ($signed(i_dat_a) < $signed(i_dat_b));
  wire lower_u = ($unsigned(i_dat_a) < $unsigned(i_dat_b));

  /**
   * Operation decoders
   */
  wire op_jump   = (i_opcode == 5'b11001) || (i_opcode == 5'b11011);
  wire op_branch = (i_opcode == 5'b11000);

  /**
   * Condition multiplexer
   *  Bits 2:1 of the funct3 are condition selectors
   *  Bit 0 tells if condition should be inverted or not
   */
  reg condition_mux;

  always @* begin
    case (i_funct3[2:1])
      2'b00:   condition_mux = equal;
      2'b10:   condition_mux = lower;
      2'b11:   condition_mux = lower_u;
      default: condition_mux = 0;
    endcase
  end

  wire condition = condition_mux ^ i_funct3[0];

  /**
   * Final branch condition
   *  Jump is always taken and branch is taken if the condition is met
   */
  wire br_en = op_jump || (op_branch && condition);

  /**
   * Output assignment
   */
  assign o_br_en = br_en;

endmodule
