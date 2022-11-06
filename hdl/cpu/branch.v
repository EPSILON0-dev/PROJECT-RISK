/****************************************************************************
 * Copyright 2022 Lukasz Forenc
 *
 * file: branch.v
 *
 * This file contains the 3 comparators used for assessing the branch
 * condition, at the end they are connected with a MUX4 and xored with the
 * contition inversion bit.
 *
 * i_dat_a  - Data input A for the comparators
 * i_dat_b  - Data input B for the comparators
 * i_funct3 - Branch condition selector
 * i_branch - Branch enable input (conditional jump)
 * i_jump   - Jump enable input (unconditional branch)
 *
 * o_br_en  - Branch enable output (routed to the fetch unit)
 ***************************************************************************/

module branch (
  input  [31:0] i_dat_a,
  input  [31:0] i_dat_b,

  input  [ 2:0] i_funct3,
  input         i_branch,
  input         i_jump,

  output        o_br_en
);


  // Branch condition comparators
  wire equal;
  wire lower;
  wire lower_u;

  // Conditiom multiplexer
  reg  condition_mux;
  wire condition;

  // Final branch condition
  wire br_en;


  /**
   * Branch condition comparators
   */
  assign equal   = (i_dat_a == i_dat_b);
  assign lower   = ($signed(i_dat_a) < $signed(i_dat_b));
  assign lower_u = ($unsigned(i_dat_a) < $unsigned(i_dat_b));

  /**
   * Condition multiplexer
   *  Bits 2:1 of the funct3 are condition selectors
   *  Bit 0 tells if condition should be inverted or not
   */
`ifdef HARDWARE_TIPS
  (* parallel_case *)
`endif
  always @* begin
    case (i_funct3[2:1])
      2'b00:   condition_mux = equal;
      2'b10:   condition_mux = lower;
      2'b11:   condition_mux = lower_u;
      default: condition_mux = 0;
    endcase
  end

  assign condition = condition_mux ^ i_funct3[0];

  /**
   * Final branch condition
   *  Jump is always taken and branch is taken if the condition is met
   */
  assign br_en = i_jump || (i_branch && condition);

  /**
   * Output assignment
   */
  assign o_br_en = br_en;

endmodule
