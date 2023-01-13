/****************************************************************************
 * Copyright 2022 Lukasz Forenc
 *
 * File: muldiv.v
 *
 * This file contains multiplier and divider circuitry for the M extension.
 * Based on the configuration data multiplier is either combitional or
 * sequential. Combinational multiplier comes with a long propagation delay
 * so there's an option to add a register that generates alu_busy signal
 * for one cycle while the signal propagates. Another bottleneck are the
 * input registers, there's an option to enable input buffer registers.
 *
 * i_clk_n  - Inverted clock input
 * i_rst    - Reset input
 * i_in_a   - Data input A (multiplicand/dividend)
 * i_in_b   - Data input B (multiplier/divisor)
 * i_funct3 - Mul/Div function selector
 * i_md_en  - Mul/Div operation enable (required to start the operation)
 *
 * o_result - Mul/Div result
 * o_busy   - Mul/Div busy signal (remains '1' until bit operation finishes)
 ***************************************************************************/
`include "config.v"

module muldiv (
  input         i_clk_n,
  input         i_rst,

  input  [31:0] i_in_a,
  input  [31:0] i_in_b,

  input  [ 2:0] i_funct3,
  input         i_md_en,

  output [31:0] o_result,
  output        o_busy
);


  // Sign signals
  wire [31:0] in_a_n;
  wire [31:0] in_b_n;
  wire        mul_a_se;
  wire        mul_b_se;
  wire        div_se;
  wire        a_se;
  wire        b_se;
  wire [31:0] a_s;
  wire [31:0] b_s;
  wire        mul_s;
  wire        div_s;
  wire        rem_s;
  wire        div_rem_s;
`ifdef M_INPUT_REG
  wire [31:0] in_a_c;
  wire [31:0] in_b_c;
  reg  [31:0] in_a;
  reg  [31:0] in_b;
`else
  wire [31:0] in_a;
  wire [31:0] in_b;
`endif

  // Enable signal
`ifdef M_INPUT_REG
  reg  md_en_t1;
`endif
  wire md_en;

  // Multiply postprocessing
  wire [63:0] mul_q;
  wire [31:0] mul;

  // Divider
  reg  [63:0] div_a;
  reg  [31:0] div_b;
  reg  [31:0] div_q;
  reg   [5:0] div_cnt;
  wire [31:0] div_sub;
  wire        div_cmp;
  wire        div_busy;
  wire        div_en;

  // Divider postprocessing
  wire [31:0] div_div;
  wire [31:0] div_rem;
  wire [31:0] div_res;
  wire [31:0] div;

  // Inverted input signals (not exactly inverted but sign inverted)
  assign in_a_n = ~i_in_a + 32'd1;
  assign in_b_n = ~i_in_b + 32'd1;

  // Sign enable signals (se for sign enable)
  assign mul_a_se = (i_funct3 == 3'b001) || (i_funct3 == 3'b010);
  assign mul_b_se = (i_funct3 == 3'b001);
  assign div_se = (i_funct3 == 3'b100) || (i_funct3 == 3'b110);
  assign a_se = mul_a_se || div_se;
  assign b_se = mul_b_se || div_se;

  // Unsigned signals (unsigned versions of input signals)
  assign a_s = (i_in_a[31]) ? in_a_n : i_in_a;
  assign b_s = (i_in_b[31]) ? in_b_n : i_in_b;

  // Sign signals (actual signs, s for sign)
  assign mul_s = (a_se && i_in_a[31]) ^ (b_se && i_in_b[31]);
  assign div_s = mul_s;
  assign rem_s = (a_se && i_in_a[31]);
  assign div_rem_s = (i_funct3[1]) ? rem_s : div_s;

  // Final inputs (unsigned or sign inverted), created either as reg or wire
`ifdef M_INPUT_REG
  always @(negedge i_clk_n) begin
    md_en_t1 <= i_md_en;
    in_a <= in_a_c;
    in_b <= in_b_c;
  end
  assign in_a_c = (a_se) ? a_s : i_in_a;
  assign in_b_c = (b_se) ? b_s : i_in_b;
  assign md_en = i_md_en && md_en_t1;
`else
  assign in_a = (a_se) ? a_s : i_in_a;
  assign in_b = (b_se) ? b_s : i_in_b;
  assign md_en = i_md_en;
`endif


  /*
   * Fast multiplier is just a verilog built-in combinational multiplier
   */
`ifdef M_FAST_MULTIPLIER

  wire [63:0] mul_mul;
  wire        mul_busy;

  assign mul_mul = $unsigned(in_a) * $unsigned(in_b);

  /*
   * DSPs in FPGAs can be a bit slow, especially when they have to do
   *  32x32bit multiplication (like in this case), this circuit creates one
   *  cycle hazard during multiplication which allows signal to overcome DSPs
   *  combinational delay and reach next phase registers
   */
`ifdef M_FAST_MUL_DELAY
  reg  mul_delay;
  wire mul_en;

  always @(posedge i_clk_n) begin
    if (i_rst) begin
      mul_delay <= 0;
    end else begin
      if (mul_delay) begin
        mul_delay <= 0;
      end else if (!mul_delay && mul_en) begin
        mul_delay <= 1'b1;
      end
    end
  end

  assign mul_en = md_en && !i_funct3[2];
  assign mul_busy = mul_delay;
`else
  assign mul_busy = 0;
`endif

  /*
   * Slow multiplier is a shift-and-add multiplier, at every clock cycle
   *  A operand is added to result if the zeroth bit in B register is set
   *  after that A operand is shifted left and B is shifted right, we keep
   *  adding shifted A until all ones are shifted out of B register
   */
`else

  // A register - multiplicand
  // B register - multiplier
  // MUL register - accumulator (product)
  reg  [63:0] mul_a_reg;
  reg  [31:0] mul_b_reg;
  reg  [63:0] mul_mul;
  wire        mul_busy;
  wire        mul_en;

  always @(posedge i_clk_n) begin
    if (i_rst) begin
      mul_a_reg <= 0;
      mul_b_reg <= 0;
      mul_mul <= 0;
    end else begin
      if (mul_en && ~|mul_b_reg) begin
        // Initial register preload
        mul_a_reg <= { 32'd0, in_a };
        mul_b_reg <= in_b;
        mul_mul <= 0;
      end else begin
        // Actual bit shifting and adding
        if (|mul_b_reg) begin
          if (mul_b_reg[0]) begin
            mul_mul <= mul_mul + mul_a_reg;
          end
          mul_a_reg <= { mul_a_reg[62:0], 1'b0 };
          mul_b_reg <= { 1'b0, mul_b_reg[31:1] };
        end
      end
    end
  end

  // Busy and enable signal
  assign mul_busy = |mul_b_reg;
  assign mul_en = md_en && !i_funct3[2];

`endif

  // Multiplier "postprocessing"
  //  If result sign is negative then the result is in inverted
  assign mul_q = (mul_s) ? (0 - mul_mul) : mul_mul;
  assign mul = (|i_funct3[1:0]) ? mul_q[63:32] : mul_q[31:0];

  /*
   * Divider
   *  Divider works by shifting left the dividend and subtracting divisor
   *  from it if the shifted value is big enough, if it is we add a one to
   *  the result and shift it (the result) left by one, we repeat this
   *  process 32 times (for all bits), and the value we are left with is a
   *  reminder.
   */
  // A register - dividend
  // B register - divisor
  // Q register - accumulator (result)
  // Divider counter

  always @(posedge i_clk_n) begin
    if (i_rst) begin
      // Reset
      div_a <= 0;
      div_b <= 0;
      div_q <= 0;
      div_cnt <= 6'b100000;
    end else begin
      if (div_en) begin
        // Register preload
        div_a <= { 32'd0, in_a };
        div_b <= in_b;
        div_q <= 0;
        div_cnt <= 0;
      end
      if (!div_cnt[5]) begin
        // Actual division
        div_cnt <= div_cnt + 5'd1;
        div_q <= { div_q[30:0], div_cmp };
        if (div_cmp) begin
          div_a <= { div_sub[31:0], div_a[30:0], 1'b0 };
        end else begin
          div_a <= { div_a[62:0], 1'b0 };
        end
      end
    end
  end

  // Divider comparator and subtractor
  assign div_sub = div_a[62:31] - div_b;
  assign div_cmp = (div_a[62:31] >= div_b);

  // Busy and enable signals
  assign div_busy = !div_cnt[5];
  assign div_en = md_en && i_funct3[2];

  // Divide "postprocessing"
  //  This is just a MUX switching between the reminder and the result
  //  Also if result sign is negative then the result is in inverted
  assign div_div = div_q;
  assign div_rem = div_a[63:32];
  assign div_res = (i_funct3[1]) ? div_rem : div_div;
  assign div = (div_rem_s) ? (0 - div_res) : div_res;

  // Final result MUX and busy signal
  assign o_result = (i_funct3[2]) ? div : mul;

`ifdef M_INPUT_REG
  // This version also generates busy signal on startup
  assign o_busy = mul_busy || div_busy || (i_md_en && !md_en);
`else
  assign o_busy = mul_busy || div_busy;
`endif

endmodule
