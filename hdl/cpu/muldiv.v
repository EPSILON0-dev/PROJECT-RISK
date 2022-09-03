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

  // Inverted input signals (not exactly inverted but sign inverted)
  wire [31:0] in_a_n = (0 - i_in_a[31:0]);
  wire [31:0] in_b_n = (0 - i_in_b[31:0]);

  // Sign enable signals (se for sign enable)
  wire mul_a_se = (i_funct3 == 3'b001) || (i_funct3 == 3'b010);
  wire mul_b_se = (i_funct3 == 3'b001);
  wire div_se = (i_funct3 == 3'b100) || (i_funct3 == 3'b110);
  wire a_se = mul_a_se || div_se;
  wire b_se = mul_b_se || div_se;

  // Unsigned signals (unsigned versions of input signals)
  wire [31:0] a_s = (i_in_a[31]) ? in_a_n : i_in_a;
  wire [31:0] b_s = (i_in_b[31]) ? in_b_n : i_in_b;

  // Sign signals (actual signs, s for sign)
  wire mul_s = (a_se && i_in_a[31]) ^ (b_se && i_in_b[31]);
  wire div_s = mul_s;
  wire rem_s = (a_se && i_in_a[31]);
  wire div_rem_s = (i_funct3[1]) ? rem_s : div_s;

  // Final inputs (unsigned or sign inverted)
  wire [31:0] in_a = (a_se) ? a_s : i_in_a;
  wire [31:0] in_b = (b_se) ? b_s : i_in_b;

  ///////////////////////////////////////////////////////////////////////////
  // Fast multiplier is just a verilog built-in combinational multiplier
  ///////////////////////////////////////////////////////////////////////////
`ifdef M_FAST_MULTIPLIER

  wire [63:0] mul_mul = in_a * in_b;
  wire        mul_busy = 0;

  ///////////////////////////////////////////////////////////////////////////
  // Slow multiplier is a shift-and-add multiplier, at every clock cycle
  //  A operand is added to result if the zeroth bit in B register is set
  //  after that A operand is shifted left and B is shifted right, we keep
  //  adding shifted A until all ones are shifted out of B register
  ///////////////////////////////////////////////////////////////////////////
`else

  // A register - multiplicand
  // B register - multiplier
  // MUL register - accumulator (product)
  reg  [63:0] mul_a_reg;
  reg  [31:0] mul_b_reg;
  reg  [63:0] mul_mul;

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
  wire mul_busy = |mul_b_reg;
  wire mul_en = i_md_en && !i_funct3[2];

`endif

  // Multiplier "postprocessing"
  //  If result sign is negative then the result is in inverted
  wire [63:0] mul_q = (mul_s) ? (0 - mul_mul) : mul_mul;
  wire [31:0] mul = (|i_funct3[1:0]) ? mul_q[63:32] : mul_q[31:0];

  ///////////////////////////////////////////////////////////////////////////
  // Divider
  //  Divider works by shifting left the dividend and subtracting divisor
  //  from it if the shifted value is big enough, if it is we add a one to
  //  the result and shift it (the result) left by one, we repeat this
  //  process 32 times (for all bits), and the value we are left with is a
  //  reminder.
  ///////////////////////////////////////////////////////////////////////////
  // A register - dividend
  // B register - divisor
  // Q register - accumulator (result)
  // Divider counter
  reg [63:0] div_a;
  reg [31:0] div_b;
  reg [31:0] div_q;
  reg [ 5:0] div_cnt = 6'b100000;

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
  wire [31:0] div_sub = div_a[62:31] - div_b;
  wire        div_cmp = (div_a[62:31] >= div_b);

  // Busy and enable signals
  wire        div_busy = !div_cnt[5];
  wire        div_en = i_md_en &&  i_funct3[2];

  // Divide "postprocessing"
  //  This is just a MUX switching between the reminder and the result
  //  Also if result sign is negative then the result is in inverted
  wire [31:0] div_div = div_q;
  wire [31:0] div_rem = div_a[63:32];
  wire [31:0] div_res = (i_funct3[1]) ? div_rem : div_div;
  wire [31:0] div = (div_rem_s) ? (0 - div_res) : div_res;

  // Final result MUX and busy signal
  assign o_result = (i_funct3[2]) ? div : mul;
  assign o_busy = mul_busy || div_busy;

endmodule
