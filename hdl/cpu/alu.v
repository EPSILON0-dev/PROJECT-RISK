/**
 * @file alu.v
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief ALU + Barrel Shifter
 * @date 2022-04-30
 *
 * "7 - 2 = 4" ~ GIGACHAD
 *
 */

module alu (
    input  [31:0] in_a,
    input  [31:0] in_b,
    input  [ 2:0] funct3,
    input         funct7_4,
    input         alu_en,
    input         alu_imm,
    output [31:0] alu_out);


    /////////////////////////////////////////////////////////////////////////
    // Adder/subtractor
    /////////////////////////////////////////////////////////////////////////
    wire        op_subtract;
    wire [31:0] adder_in_b;
    wire [31:0] adder_out;

    assign op_subtract = alu_en && !alu_imm && funct7_4;
    assign adder_in_b = (op_subtract) ? ~in_b : in_b;
    assign adder_out = in_a + adder_in_b + {31'd0, op_subtract};


    /////////////////////////////////////////////////////////////////////////
    // Barrel shifter
    /////////////////////////////////////////////////////////////////////////
    wire op_sll;
    wire op_srl;
    wire op_sra;
    wire [ 4:0] shift_amount;
    wire [31:0] shift_mask;
    wire [31:0] shift_out;
    wire [31:0] shift_sll;
    wire [31:0] shift_srl;
    wire [31:0] shift_sra;
    wire [31:0] shift_combined;

    // Shifter
    alu_shifter shifter (
        .shift   (shift_amount),
        .in_val  (in_a),
        .out_val (shift_out)
    );

    // Mask
    alu_mask_lut mask_lut (
        .shift (shift_amount),
        .mask  (shift_mask)
    );

    // Operation decoder
    assign op_sll = alu_en && (funct3 == 3'b001);
    assign op_srl = alu_en && (funct3 == 3'b101) && !funct7_4;
    assign op_sra = alu_en && (funct3 == 3'b101) &&  funct7_4;
    assign shift_amount = (op_sll) ? in_b[4:0] : (5'd0 - in_b[4:0]);

    // Shift "postprocessing"
    assign shift_sll = shift_out & ~shift_mask;
    assign shift_srl = shift_out & shift_mask;
    assign shift_sra = shift_srl | (~shift_mask & {32{in_a[31]}});

    // Final shift mux
    assign shift_combined = (|shift_amount)?
        ((op_sra)? shift_sra : (op_srl)? shift_srl : shift_sll) : in_a;


    /////////////////////////////////////////////////////////////////////////
    // Logic operators
    /////////////////////////////////////////////////////////////////////////
    wire [31:0] logic_xor;
    wire [31:0] logic_or;
    wire [31:0] logic_and;

    assign logic_xor = in_a ^ in_b;
    assign logic_or  = in_a | in_b;
    assign logic_and = in_a & in_b;


    /////////////////////////////////////////////////////////////////////////
    // Signed/unsigned comparator
    /////////////////////////////////////////////////////////////////////////
    wire [31:0] comp_signed;
    wire [31:0] comp_unsigned;

    assign comp_signed   = {31'd0, (  $signed(in_a) <   $signed(in_b))};
    assign comp_unsigned = {31'd0, ($unsigned(in_a) < $unsigned(in_b))};


    /////////////////////////////////////////////////////////////////////////
    // Final mux
    /////////////////////////////////////////////////////////////////////////
    wire [31:0] mux_01, mux_23, mux_45, mux_67;
    wire [31:0] mux_03, mux_47;
    wire [31:0] mux_07;

    assign mux_01 = (funct3[0] && alu_en) ? shift_combined : adder_out;
    assign mux_23 = (funct3[0] && alu_en) ? comp_unsigned  : comp_signed;
    assign mux_45 = (funct3[0] && alu_en) ? shift_combined : logic_xor;
    assign mux_67 = (funct3[0] && alu_en) ? logic_and      : logic_or;

    assign mux_03 = (funct3[1] && alu_en) ? mux_23 : mux_01;
    assign mux_47 = (funct3[1] && alu_en) ? mux_67 : mux_45;

    assign mux_07 = (funct3[2] && alu_en) ? mux_47 : mux_03;


    /////////////////////////////////////////////////////////////////////////
    // Output assignment
    /////////////////////////////////////////////////////////////////////////
    assign alu_out = mux_07;

endmodule



/////////////////////////////////////////////////////////////////////////////
// This module is the actual barrel shifter implemented with "case"
/////////////////////////////////////////////////////////////////////////////
module alu_shifter (
    input      [ 4:0] shift,
    input      [31:0] in_val,
    output reg [31:0] out_val);

    always @* begin
        case (shift)
            default: out_val = in_val;
            5'h01:   out_val = {in_val[30:0], in_val[31]};
            5'h02:   out_val = {in_val[29:0], in_val[31:30]};
            5'h03:   out_val = {in_val[28:0], in_val[31:29]};
            5'h04:   out_val = {in_val[27:0], in_val[31:28]};
            5'h05:   out_val = {in_val[26:0], in_val[31:27]};
            5'h06:   out_val = {in_val[25:0], in_val[31:26]};
            5'h07:   out_val = {in_val[24:0], in_val[31:25]};
            5'h08:   out_val = {in_val[23:0], in_val[31:24]};
            5'h09:   out_val = {in_val[22:0], in_val[31:23]};
            5'h0A:   out_val = {in_val[21:0], in_val[31:22]};
            5'h0B:   out_val = {in_val[20:0], in_val[31:21]};
            5'h0C:   out_val = {in_val[19:0], in_val[31:20]};
            5'h0D:   out_val = {in_val[18:0], in_val[31:19]};
            5'h0E:   out_val = {in_val[17:0], in_val[31:18]};
            5'h0F:   out_val = {in_val[16:0], in_val[31:17]};
            5'h10:   out_val = {in_val[15:0], in_val[31:16]};
            5'h11:   out_val = {in_val[14:0], in_val[31:15]};
            5'h12:   out_val = {in_val[13:0], in_val[31:14]};
            5'h13:   out_val = {in_val[12:0], in_val[31:13]};
            5'h14:   out_val = {in_val[11:0], in_val[31:12]};
            5'h15:   out_val = {in_val[10:0], in_val[31:11]};
            5'h16:   out_val = {in_val[9:0], in_val[31:10]};
            5'h17:   out_val = {in_val[8:0], in_val[31:9]};
            5'h18:   out_val = {in_val[7:0], in_val[31:8]};
            5'h19:   out_val = {in_val[6:0], in_val[31:7]};
            5'h1A:   out_val = {in_val[5:0], in_val[31:6]};
            5'h1B:   out_val = {in_val[4:0], in_val[31:5]};
            5'h1C:   out_val = {in_val[3:0], in_val[31:4]};
            5'h1D:   out_val = {in_val[2:0], in_val[31:3]};
            5'h1E:   out_val = {in_val[1:0], in_val[31:2]};
            5'h1F:   out_val = {in_val[0], in_val[31:1]};
        endcase
    end

endmodule



/////////////////////////////////////////////////////////////////////////////
// This module contains the LUT for the shift mask
/////////////////////////////////////////////////////////////////////////////
module alu_mask_lut (
    input      [ 4:0] shift,
    output reg [31:0] mask);

    always @* begin
        case (shift)
            default: mask = 32'h00000000;
            5'h01:   mask = 32'h00000001;
            5'h02:   mask = 32'h00000003;
            5'h03:   mask = 32'h00000007;
            5'h04:   mask = 32'h0000000F;
            5'h05:   mask = 32'h0000001F;
            5'h06:   mask = 32'h0000003F;
            5'h07:   mask = 32'h0000007F;
            5'h08:   mask = 32'h000001FF;
            5'h09:   mask = 32'h000001FF;
            5'h0A:   mask = 32'h000003FF;
            5'h0B:   mask = 32'h000007FF;
            5'h0C:   mask = 32'h00000FFF;
            5'h0D:   mask = 32'h00001FFF;
            5'h0E:   mask = 32'h00003FFF;
            5'h0F:   mask = 32'h00007FFF;
            5'h10:   mask = 32'h0000FFFF;
            5'h11:   mask = 32'h0001FFFF;
            5'h12:   mask = 32'h0003FFFF;
            5'h13:   mask = 32'h0007FFFF;
            5'h14:   mask = 32'h000FFFFF;
            5'h15:   mask = 32'h001FFFFF;
            5'h16:   mask = 32'h003FFFFF;
            5'h17:   mask = 32'h007FFFFF;
            5'h18:   mask = 32'h00FFFFFF;
            5'h19:   mask = 32'h01FFFFFF;
            5'h1A:   mask = 32'h03FFFFFF;
            5'h1B:   mask = 32'h07FFFFFF;
            5'h1C:   mask = 32'h0FFFFFFF;
            5'h1D:   mask = 32'h1FFFFFFF;
            5'h1E:   mask = 32'h3FFFFFFF;
            5'h1F:   mask = 32'h7FFFFFFF;
        endcase
    end

endmodule
