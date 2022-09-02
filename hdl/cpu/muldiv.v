`include "config.v"

module muldiv (
  input         i_clk_n,

  input  [31:0] i_in_a,
  input  [31:0] i_in_b,

  input  [ 2:0] i_funct3,
  input         i_md_en,

  output [31:0] o_result,
  output        o_busy
);

  // Inverted input signals
  wire [31:0] in_a_n = (0 - i_in_a[31:0]);
  wire [31:0] in_b_n = (0 - i_in_b[31:0]);

  // Sign enable signals
  wire md_m_a_signed = (i_funct3 == 3'b001) || (i_funct3 == 3'b010);
  wire md_m_b_signed = (i_funct3 == 3'b001);
  wire md_d_a_signed = (i_funct3 == 3'b100) || (i_funct3 == 3'b110);
  wire md_d_b_signed = (i_funct3 == 3'b100) || (i_funct3 == 3'b110);
  wire md_sign_a = md_m_a_signed || md_d_a_signed;
  wire md_sign_b = md_m_b_signed || md_d_b_signed;

  // Sign signals
  wire [31:0] md_in_a = (i_in_a[31]) ? in_a_n : i_in_a;
  wire [31:0] md_in_b = (i_in_b[31]) ? in_b_n : i_in_b;
  wire md_m_sign = (md_sign_a && i_in_a[31]) ^ (md_sign_b && i_in_b[31]);
  wire md_div_sign = (md_sign_a && i_in_a[31]) ^ (md_sign_b && i_in_b[31]);
  wire md_rem_sign = (md_sign_a && i_in_a[31]);
  wire md_d_sign = (i_funct3[1]) ? md_rem_sign : md_div_sign;

  // Final inputs
  wire [31:0] md_a = (md_sign_a) ? md_in_a : i_in_a;
  wire [31:0] md_b = (md_sign_b) ? md_in_b : i_in_b;

  // Multiplier
`ifdef FAST_MULTIPLIER

  wire [63:0] md_m_mul = md_a * md_b;
  wire        md_m_busy = 0;

`else

  reg  [63:0] md_m_a_reg = 0;
  reg  [31:0] md_m_b_reg = 0;
  reg  [63:0] md_m_mul = 0;

  always @(posedge i_clk_n) begin
    if (md_m_en && ~|md_m_b_reg) begin
      md_m_a_reg <= { 32'd0, md_a };
      md_m_b_reg <= md_b;
      md_m_mul <= 0;
    end else begin
      if (|md_m_b_reg) begin
        if (md_m_b_reg[0]) begin
          md_m_mul <= md_m_mul + md_m_a_reg;
        end
        md_m_a_reg <= { md_m_a_reg[62:0], 1'b0 };
        md_m_b_reg <= { 1'b0, md_m_b_reg[31:1] };
      end
    end
  end

  wire md_m_busy = |md_m_b_reg;
  wire md_m_en = i_md_en && !i_funct3[2];

`endif

  // Multiplier "postprocessing"
  wire [63:0] md_m_q = (md_m_sign) ? (0 - md_m_mul) : md_m_mul;
  wire [31:0] md_mul = (|i_funct3[1:0]) ? md_m_q[63:32] : md_m_q[31:0];

  // Divider
  reg [63:0] md_d_a = 0;
  reg [31:0] md_d_b = 0;
  reg [31:0] md_d_q = 0;
  reg [ 5:0] md_d_cnt = 6'b100000;

  always @(posedge i_clk_n) begin
    if (md_d_en) begin
      md_d_a <= { 32'd0, md_a };
      md_d_b <= md_b;
      md_d_q <= 0;
      md_d_cnt <= 0;
    end

    if (!md_d_cnt[5]) begin
      md_d_cnt <= md_d_cnt + 5'd1;
      md_d_q <= { md_d_q[30:0], div_cmp };

      if (div_cmp) begin
        md_d_a <= { md_d_sub[31:0], md_d_a[30:0], 1'b0 };
      end else begin
        md_d_a <= { md_d_a[62:0], 1'b0 };
      end
    end
  end

  wire [31:0] md_d_sub = md_d_a[62:31] - md_d_b;
  wire        div_cmp = (md_d_a[62:31] >= md_d_b);
  wire        md_d_busy = !md_d_cnt[5];
  wire        md_d_en = i_md_en &&  i_funct3[2];

  // Divide "postprocessing"
  wire [31:0] md_d_div = md_d_q;
  wire [31:0] md_d_rem = md_d_a[63:32];
  wire [31:0] md_d_res = (i_funct3[1]) ? md_d_rem : md_d_div;
  wire [31:0] md_div = (md_d_sign) ? (0 - md_d_res) : md_d_res;

  // Final mux
  assign o_result = (i_funct3[2]) ? md_div : md_mul;
  assign o_busy = md_m_busy || md_d_busy;

endmodule
