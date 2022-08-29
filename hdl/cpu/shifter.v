`include "config.v"

module shifter (
  input         i_clk_n,

  input  [31:0] i_in_a,
  input  [ 4:0] i_in_b,

  input  [ 2:0] i_funct3,
  input         i_funct7_5,
  input         i_alu_en,

  output [31:0] o_result,
  output        o_busy
);

  ///////////////////////////////////////////////////////////////////////////
  // Common signals
  ///////////////////////////////////////////////////////////////////////////

  // Operation decoder
  wire op_sll   = i_alu_en && (i_funct3 == 3'b001);
  wire op_srl   = i_alu_en && (i_funct3 == 3'b101) && !i_funct7_5;
  wire op_sra   = i_alu_en && (i_funct3 == 3'b101) &&  i_funct7_5;


`ifdef BARREL_SHIFTER
  ///////////////////////////////////////////////////////////////////////////
  // Barrel Shifter
  ///////////////////////////////////////////////////////////////////////////
  // Barrel shifter works in two stages:
  //  Stage 1: value is rotated (not shifted) by given amount of bits
  //  Stage 2: rotated value is masked to form final value

  // Shift mask ROM (propably will be implemented in LUT5s)
  wire [31:0] shift_mask_array [0:31];
  for (genvar i = 0; i < 32; i = i + 1) begin
    assign shift_mask_array[i] = (1 << i) - 1;
  end
  wire [31:0] shift_mask = shift_mask_array[shift_amount];

  // Length decoder (length is inverted in right shifts in order to use the
  //  same curcuitry as for left shifts)
  wire [4:0] shift_amount = (op_sll) ? i_in_b[4:0] : (5'd0 - i_in_b[4:0]);

  // Shifter/rotator (stage 1)
  wire [31:0] shift_array [0:31];
  assign shift_array[0] = i_in_a;
  for (genvar i = 0; i < 31; i = i + 1) begin
    assign shift_array[i+1] = { i_in_a[30-i:0], i_in_a[31:31-i] };
  end
  wire [31:0] shift_out = shift_array[shift_amount];

  // Shift masking (stage 2)
  wire [31:0] shift_sll = shift_out & ~shift_mask;
  wire [31:0] shift_srl = shift_out & shift_mask;
  wire [31:0] shift_sra = shift_srl | (~shift_mask & {32{i_in_a[31]}});

  // Final shift mux
  assign o_result = (|shift_amount) ?
    ((op_sra) ? shift_sra : (op_srl) ? shift_srl : shift_sll) : i_in_a;

  // Busy signal
  assign o_busy = 0;


`else
  ///////////////////////////////////////////////////////////////////////////
  // Bit Shifter
  ///////////////////////////////////////////////////////////////////////////
  // In bit shifter we set shift_amount register to shift amount and decrease
  //  it by one while shifting one bit, we repeat this until shift_amount
  //  reaches zero, then we are left with the shift result.
  reg [31:0] shift_result = 0;
  reg [ 4:0] shift_amount = 0;
  reg        shift_dir_left = 0;

  always @(posedge i_clk_n) begin

    // Initial register preload
    if (op_shift && shift_amount == 0) begin
      shift_amount   <= i_in_b[4:0];
      shift_result   <= i_in_a;
      shift_dir_left <= op_sll;
    end

    // Actual shifting
    if (shift_amount != 0) begin
      shift_result <= (shift_dir_left) ? shift_left : shift_right;
      shift_amount <= shift_amount - 5'h1;
    end

  end

  // Operation decoder
  wire op_shift = op_sll || op_srl || op_sra;

  // Shift signals
  wire [31:0] shift_right = {shift_result[31] && op_sra, shift_result[31:1]};
  wire [31:0] shift_left  = {shift_result[30:0], 1'b0};

  // Output signals
  assign o_result = shift_result;
  assign o_busy = (shift_amount != 0);

`endif

endmodule
