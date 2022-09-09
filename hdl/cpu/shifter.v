`include "config.v"

module shifter (
  // verilator lint_off unused
  input         i_clk_n,
  // verilator lint_on unused

  input  [31:0] i_in_a,
  input  [ 4:0] i_in_b,

  input  [ 2:0] i_funct3,
  input         i_op_alt,
  input         i_shift_en,

  output [31:0] o_result,
  output        o_busy
);


  // Operation signals
  wire op_sll;
  wire op_srl;
  wire op_sra;

  /**
   * Common signals
   */
  assign op_sll = i_shift_en && (i_funct3 == 3'b001);
  assign op_srl = i_shift_en && (i_funct3 == 3'b101) && !i_op_alt;
  assign op_sra = i_shift_en && (i_funct3 == 3'b101) &&  i_op_alt;

  /**
   * Barrel Shifter
   *  Barrel shifter works in two stages:
   *  Stage 1: value is rotated (not shifted) by given amount of bits
   *  Stage 2: rotated value is masked to form final value
   */
`ifdef BARREL_SHIFTER
  // Shift mask
  wire [31:0] shift_mask_array [0:31];
  wire [31:0] shift_mask;

  // Amount decoder
  wire  [4:0] shift_amount;

  // Shifter/rotator
  wire [31:0] shift_array [0:31];
  wire [31:0] shift_out;

  // Shift masking
  wire [31:0] shift_sll;
  wire [31:0] shift_srl;
  wire [31:0] shift_sra;

  // Shift mask ROM (propably will be implemented in LUT5s)
  for (genvar i = 0; i < 32; i = i + 1) begin
    assign shift_mask_array[i] = (1 << i) - 1;
  end
  assign shift_mask = shift_mask_array[shift_amount];

  // Length decoder (length is inverted in right shifts in order to use the
  //  same curcuitry as for left shifts)
  assign shift_amount = (op_sll) ? i_in_b[4:0] : (5'd0 - i_in_b[4:0]);

  // Shifter/rotator (stage 1)
  assign shift_array[0] = i_in_a;
  for (genvar i = 0; i < 31; i = i + 1) begin
    assign shift_array[i+1] = { i_in_a[30-i:0], i_in_a[31:31-i] };
  end
  assign shift_out = shift_array[shift_amount];

  // Shift masking (stage 2)
  assign shift_sll = shift_out & ~shift_mask;
  assign shift_srl = shift_out & shift_mask;
  assign shift_sra = shift_srl | (~shift_mask & {32{i_in_a[31]}});

  // Final shift mux
  assign o_result = (|shift_amount) ?
    ((op_sra) ? shift_sra : (op_srl) ? shift_srl : shift_sll) : i_in_a;

  // Busy signal
  assign o_busy = 0;

`else
  /**
   * Bit Shifter
   *  In bit shifter we set shift_amount register to shift amount and
   *  decrease it by one while shifting one bit, we repeat this until
   *  shift_amount reaches zero, then we are left with the shift result.
   */

  // Bit shifter
  reg  [31:0] shift_result = 0;
  reg   [4:0] shift_amount = 0;
  reg         shift_dir_left = 0;

  // Operation decoder
  wire        op_shift;

  // Shift signals
  wire [31:0] shift_right;
  wire [31:0] shift_left;

  always @(posedge i_clk_n) begin

    // Initial register preload
    if (op_shift && ~|shift_amount) begin
      shift_amount   <= i_in_b[4:0];
      shift_result   <= i_in_a;
      shift_dir_left <= op_sll;
    end

    // Actual shifting
    if (|shift_amount) begin
      shift_result <= (shift_dir_left) ? shift_left : shift_right;
      shift_amount <= shift_amount - 5'h1;
    end

  end

  // Operation decoder
  assign op_shift = op_sll || op_srl || op_sra;

  // Shift signals
  assign shift_right = {shift_result[31] && op_sra, shift_result[31:1]};
  assign shift_left  = {shift_result[30:0], 1'b0};

  // Output signals
  assign o_result = shift_result;
  assign o_busy = |shift_amount;

`endif

endmodule
