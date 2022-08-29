module branch (
  input  [31:0] i_dat_a,
  input  [31:0] i_dat_b,

  input  [ 2:0] i_funct3,
  input  [ 4:0] i_opcode,

  output        o_br_en
);


  ///////////////////////////////////////////////////////////////////////////
  // Comparators
  ///////////////////////////////////////////////////////////////////////////
  wire equal   = (i_dat_a == i_dat_b);
  wire lower   = ($signed(i_dat_a) < $signed(i_dat_b));
  wire lower_u = ($unsigned(i_dat_a) < $unsigned(i_dat_b));


  ///////////////////////////////////////////////////////////////////////////
  // Operation decoders
  ///////////////////////////////////////////////////////////////////////////
  wire op_jump   = (i_opcode == 5'b11001) || (i_opcode == 5'b11011);
  wire op_branch = (i_opcode == 5'b11000);


  ///////////////////////////////////////////////////////////////////////////
  // Condition multiplexer
  ///////////////////////////////////////////////////////////////////////////
  reg condition;

  always @* begin
    case (i_funct3)
      3'b000:  condition = equal;
      3'b001:  condition = !equal;
      3'b100:  condition = lower;
      3'b101:  condition = !lower;
      3'b110:  condition = lower_u;
      3'b111:  condition = !lower_u;
      default: condition = 0;
    endcase
  end


  ///////////////////////////////////////////////////////////////////////////
  // Final multiplexer
  ///////////////////////////////////////////////////////////////////////////
  wire br_en = op_jump || (op_branch && condition);


  ///////////////////////////////////////////////////////////////////////////
  // Output assignment
  ///////////////////////////////////////////////////////////////////////////
  assign o_br_en = br_en;

endmodule
