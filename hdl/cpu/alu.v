module alu (
    input  [31:0] i_in_a,
    input  [31:0] i_in_b,
    input  [ 2:0] i_funct3,
    input         i_funct7_4,
    input         i_alu_en,
    input         i_alu_imm,
    output [31:0] o_alu_out);


    /////////////////////////////////////////////////////////////////////////
    // Adder/subtractor
    /////////////////////////////////////////////////////////////////////////
    wire        op_subtract;
    wire [31:0] adder_in_b;
    wire [31:0] adder_out;

    assign op_subtract = i_alu_en && !i_alu_imm && i_funct7_4;
    assign adder_in_b = (op_subtract) ? ~i_in_b : i_in_b;
    assign adder_out = i_in_a + adder_in_b + {31'd0, op_subtract};


    /////////////////////////////////////////////////////////////////////////
    // Barrel shifter
    /////////////////////////////////////////////////////////////////////////
    // Barrel shifter works in two stages:
    //  Stage 1: value is rotated (not shifted) by given amount of bits
    //  Stage 2: rotated value is masked to form final value
    wire op_sll;
    wire op_srl;
    wire op_sra;
    wire [ 4:0] shift_amount;
    reg  [31:0] shift_mask;
    reg  [31:0] shift_out;
    wire [31:0] shift_sll;
    wire [31:0] shift_srl;
    wire [31:0] shift_sra;
    wire [31:0] shift_combined;

    // Shifter
    always @* begin
        case (shift_amount)
            default: shift_out = i_in_a;
            5'h01:   shift_out = { i_in_a[30:0], i_in_a[31] };
            5'h02:   shift_out = { i_in_a[29:0], i_in_a[31:30] };
            5'h03:   shift_out = { i_in_a[28:0], i_in_a[31:29] };
            5'h04:   shift_out = { i_in_a[27:0], i_in_a[31:28] };
            5'h05:   shift_out = { i_in_a[26:0], i_in_a[31:27] };
            5'h06:   shift_out = { i_in_a[25:0], i_in_a[31:26] };
            5'h07:   shift_out = { i_in_a[24:0], i_in_a[31:25] };
            5'h08:   shift_out = { i_in_a[23:0], i_in_a[31:24] };
            5'h09:   shift_out = { i_in_a[22:0], i_in_a[31:23] };
            5'h0A:   shift_out = { i_in_a[21:0], i_in_a[31:22] };
            5'h0B:   shift_out = { i_in_a[20:0], i_in_a[31:21] };
            5'h0C:   shift_out = { i_in_a[19:0], i_in_a[31:20] };
            5'h0D:   shift_out = { i_in_a[18:0], i_in_a[31:19] };
            5'h0E:   shift_out = { i_in_a[17:0], i_in_a[31:18] };
            5'h0F:   shift_out = { i_in_a[16:0], i_in_a[31:17] };
            5'h10:   shift_out = { i_in_a[15:0], i_in_a[31:16] };
            5'h11:   shift_out = { i_in_a[14:0], i_in_a[31:15] };
            5'h12:   shift_out = { i_in_a[13:0], i_in_a[31:14] };
            5'h13:   shift_out = { i_in_a[12:0], i_in_a[31:13] };
            5'h14:   shift_out = { i_in_a[11:0], i_in_a[31:12] };
            5'h15:   shift_out = { i_in_a[10:0], i_in_a[31:11] };
            5'h16:   shift_out = { i_in_a[9:0], i_in_a[31:10] };
            5'h17:   shift_out = { i_in_a[8:0], i_in_a[31:9] };
            5'h18:   shift_out = { i_in_a[7:0], i_in_a[31:8] };
            5'h19:   shift_out = { i_in_a[6:0], i_in_a[31:7] };
            5'h1A:   shift_out = { i_in_a[5:0], i_in_a[31:6] };
            5'h1B:   shift_out = { i_in_a[4:0], i_in_a[31:5] };
            5'h1C:   shift_out = { i_in_a[3:0], i_in_a[31:4] };
            5'h1D:   shift_out = { i_in_a[2:0], i_in_a[31:3] };
            5'h1E:   shift_out = { i_in_a[1:0], i_in_a[31:2] };
            5'h1F:   shift_out = { i_in_a[0], i_in_a[31:1] };
        endcase
    end

    // Mask
    always @* begin
        case (shift_amount)
            default: shift_mask = 32'h00000000;
            5'h01:   shift_mask = 32'h00000001;
            5'h02:   shift_mask = 32'h00000003;
            5'h03:   shift_mask = 32'h00000007;
            5'h04:   shift_mask = 32'h0000000F;
            5'h05:   shift_mask = 32'h0000001F;
            5'h06:   shift_mask = 32'h0000003F;
            5'h07:   shift_mask = 32'h0000007F;
            5'h08:   shift_mask = 32'h000001FF;
            5'h09:   shift_mask = 32'h000001FF;
            5'h0A:   shift_mask = 32'h000003FF;
            5'h0B:   shift_mask = 32'h000007FF;
            5'h0C:   shift_mask = 32'h00000FFF;
            5'h0D:   shift_mask = 32'h00001FFF;
            5'h0E:   shift_mask = 32'h00003FFF;
            5'h0F:   shift_mask = 32'h00007FFF;
            5'h10:   shift_mask = 32'h0000FFFF;
            5'h11:   shift_mask = 32'h0001FFFF;
            5'h12:   shift_mask = 32'h0003FFFF;
            5'h13:   shift_mask = 32'h0007FFFF;
            5'h14:   shift_mask = 32'h000FFFFF;
            5'h15:   shift_mask = 32'h001FFFFF;
            5'h16:   shift_mask = 32'h003FFFFF;
            5'h17:   shift_mask = 32'h007FFFFF;
            5'h18:   shift_mask = 32'h00FFFFFF;
            5'h19:   shift_mask = 32'h01FFFFFF;
            5'h1A:   shift_mask = 32'h03FFFFFF;
            5'h1B:   shift_mask = 32'h07FFFFFF;
            5'h1C:   shift_mask = 32'h0FFFFFFF;
            5'h1D:   shift_mask = 32'h1FFFFFFF;
            5'h1E:   shift_mask = 32'h3FFFFFFF;
            5'h1F:   shift_mask = 32'h7FFFFFFF;
        endcase
    end

    // Operation decoder
    assign op_sll = i_alu_en && (i_funct3 == 3'b001);
    assign op_srl = i_alu_en && (i_funct3 == 3'b101) && !i_funct7_4;
    assign op_sra = i_alu_en && (i_funct3 == 3'b101) &&  i_funct7_4;
    assign shift_amount = (op_sll) ? i_in_b[4:0] : (5'd0 - i_in_b[4:0]);

    // Shift "postprocessing"
    assign shift_sll = shift_out & ~shift_mask;
    assign shift_srl = shift_out & shift_mask;
    assign shift_sra = shift_srl | (~shift_mask & {32{i_in_a[31]}});

    // Final shift mux
    assign shift_combined = (|shift_amount)?
        ((op_sra)? shift_sra : (op_srl)? shift_srl : shift_sll) : i_in_a;


    /////////////////////////////////////////////////////////////////////////
    // Logic operators
    /////////////////////////////////////////////////////////////////////////
    wire [31:0] logic_xor;
    wire [31:0] logic_or;
    wire [31:0] logic_and;

    assign logic_xor = i_in_a ^ i_in_b;
    assign logic_or  = i_in_a | i_in_b;
    assign logic_and = i_in_a & i_in_b;


    /////////////////////////////////////////////////////////////////////////
    // Signed/unsigned comparator
    /////////////////////////////////////////////////////////////////////////
    wire [31:0] comp_signed;
    wire [31:0] comp_unsigned;

    assign comp_signed   = {31'd0, (  $signed(i_in_a) <   $signed(i_in_b))};
    assign comp_unsigned = {31'd0, ($unsigned(i_in_a) < $unsigned(i_in_b))};


    /////////////////////////////////////////////////////////////////////////
    // Final mux
    /////////////////////////////////////////////////////////////////////////
    wire [31:0] mux_01, mux_23, mux_45, mux_67;
    wire [31:0] mux_03, mux_47;
    wire [31:0] mux_07;

    assign mux_01 = (i_funct3[0] && i_alu_en) ? shift_combined : adder_out;
    assign mux_23 = (i_funct3[0] && i_alu_en) ? comp_unsigned  : comp_signed;
    assign mux_45 = (i_funct3[0] && i_alu_en) ? shift_combined : logic_xor;
    assign mux_67 = (i_funct3[0] && i_alu_en) ? logic_and      : logic_or;

    assign mux_03 = (i_funct3[1] && i_alu_en) ? mux_23 : mux_01;
    assign mux_47 = (i_funct3[1] && i_alu_en) ? mux_67 : mux_45;

    assign mux_07 = (i_funct3[2] && i_alu_en) ? mux_47 : mux_03;


    /////////////////////////////////////////////////////////////////////////
    // Output assignment
    /////////////////////////////////////////////////////////////////////////
    assign o_alu_out = mux_07;

endmodule
