`include "../alu.v"
//`define DUMP

module alu_tb;

    /////////////////////////////////////////////////////////////////////////
    // Test Array
    /////////////////////////////////////////////////////////////////////////
    parameter arr_sizes = 48;
    reg  [31:0] lut_in_a[0:arr_sizes-1];
    reg  [31:0] lut_in_b[0:arr_sizes-1];
    reg  [31:0] lut_result[0:arr_sizes-1];

    /////////////////////////////////////////////////////////////////////////
    // Enable dump file if defined
    /////////////////////////////////////////////////////////////////////////
    `ifdef DUMP
    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, DUT);
    end
    `endif


    /////////////////////////////////////////////////////////////////////////
    // Enable monitoring
    /////////////////////////////////////////////////////////////////////////
    initial begin
        $monitor("%d,\t%h,\t%h,\t%h,\t%b",
            $time, in_a, in_b, alu_out, test_res);
    end


    /////////////////////////////////////////////////////////////////////////
    // Device under test
    /////////////////////////////////////////////////////////////////////////
    reg  [31:0] in_a;
    reg  [31:0] in_b;
    reg  [ 2:0] funct3;
    reg         funct7_4;
    reg         alu_en;
    reg         alu_imm;
    wire [31:0] alu_out;
    wire test_res;

    alu DUT (
        .i_in_a     (in_a),
        .i_in_b     (in_b),
        .i_funct3   (funct3),
        .i_funct7_4 (funct7_4),
        .i_alu_en   (alu_en),
        .i_alu_imm  (alu_imm),
        .o_alu_out  (alu_out)
    );

    // verilator lint_off WIDTH
    assign test_res = (alu_out == lut_result[$time]);

    always begin
        in_a = lut_in_a[$time];
        in_b = lut_in_b[$time];
        #1;
    end
    // verilator lint_on WIDTH

    // This fixes undefined state at time 0
    initial begin
        $monitor("%d,\t%h,\t%h,\t%h,\t%b", $time, in_a, in_b, alu_out, test_res);
        in_a = 0;
        in_b = 0;
    end

    /////////////////////////////////////////////////////////////////////////
    // Test Cases
    /////////////////////////////////////////////////////////////////////////
    initial begin
        $display("\n\n\t\t\t\t----==== ADD ====----");
        $display("\t\ttime\tin_a,\t\tin_b,\t\tout,\t\tResult");
        funct3 = 0;
        funct7_4 = 0;
        alu_en = 1;
        alu_imm = 0;

        lut_in_a[0] = 32'd0;
        lut_in_b[0] = 32'd0;
        lut_result[0] = 32'd0;

        lut_in_a[1] = 32'd1;
        lut_in_b[1] = 32'd1;
        lut_result[1] = 32'd2;

        lut_in_a[2] = 32'd3;
        lut_in_b[2] = 32'd7;
        lut_result[2] = 32'd10;

        lut_in_a[3] = 32'h00000000;
        lut_in_b[3] = 32'hffff8000;
        lut_result[3] = 32'hffff8000;

        lut_in_a[4] = 32'h80000000;
        lut_in_b[4] = 32'h00000000;
        lut_result[4] = 32'h80000000;

        lut_in_a[5] = 32'hffff8000;
        lut_in_b[5] = 32'h80000000;
        lut_result[5] = 32'h7fff8000;

        lut_in_a[6] = 32'hFFFFFFFF;
        lut_in_b[6] = 32'h00000001;
        lut_result[6] = 32'h00000000;

        lut_in_a[7] = 32'h00000001;
        lut_in_b[7] = 32'h7FFFFFFF;
        lut_result[7] = 32'h80000000;

        #8;

        $display("\n\n\t\t\t\t----==== SUB ====----");
        $display("\t\ttime\tin_a,\t\tin_b,\t\tout,\t\tResult");
        funct3 = 0;
        funct7_4 = 1;
        alu_en = 1;
        alu_imm = 0;

        lut_in_a[8] = 32'd0;
        lut_in_b[8] = 32'd0;
        lut_result[8] = 32'd0;

        lut_in_a[9] = 32'd1;
        lut_in_b[9] = 32'd1;
        lut_result[9] = 32'd0;

        lut_in_a[10] = 32'd3;
        lut_in_b[10] = 32'd7;
        lut_result[10] = 32'hfffffffc;

        lut_in_a[11] = 32'h00000000;
        lut_in_b[11] = 32'hffffffff;
        lut_result[11] = 32'h00000001;

        #4;

        $display("\n\n\t\t\t\t----==== SLL ====----");
        $display("\t\ttime\tin_a,\t\tin_b,\t\tout,\t\tResult");
        funct3 = 1;
        funct7_4 = 0;
        alu_en = 1;
        alu_imm = 0;

        lut_in_a[12] = 32'h21212121;
        lut_in_b[12] = 32'd0;
        lut_result[12] = 32'h21212121;

        lut_in_a[13] = 32'h21212121;
        lut_in_b[13] = 32'd1;
        lut_result[13] = 32'h42424242;

        lut_in_a[14] = 32'h21212121;
        lut_in_b[14] = 32'd14;
        lut_result[14] = 32'h48484000;

        lut_in_a[15] = 32'h21212121;
        lut_in_b[15] = 32'd31;
        lut_result[15] = 32'h80000000;

        #4;

        $display("\n\n\t\t\t\t----==== SLT ====----");
        $display("\t\ttime\tin_a,\t\tin_b,\t\tout,\t\tResult");
        funct3 = 2;
        funct7_4 = 0;
        alu_en = 1;
        alu_imm = 0;

        lut_in_a[16] = 32'h80000001;
        lut_in_b[16] = 32'h00000001;
        lut_result[16] = 32'h00000001;

        lut_in_a[17] = 32'h00000001;
        lut_in_b[17] = 32'h00000003;
        lut_result[17] = 32'h00000001;

        lut_in_a[18] = 32'h00000007;
        lut_in_b[18] = 32'h00000003;
        lut_result[18] = 32'h00000000;

        lut_in_a[19] = 32'hffffffff;
        lut_in_b[19] = 32'h7fffffff;
        lut_result[19] = 32'h00000001;

        #4;

        $display("\n\n\t\t\t\t----==== SLTU ====----");
        $display("\t\ttime\tin_a,\t\tin_b,\t\tout,\t\tResult");
        funct3 = 3;
        funct7_4 = 0;
        alu_en = 1;
        alu_imm = 0;

        lut_in_a[20] = 32'h80000000;
        lut_in_b[20] = 32'h00000001;
        lut_result[20] = 32'h00000000;

        lut_in_a[21] = 32'h00000001;
        lut_in_b[21] = 32'h00000003;
        lut_result[21] = 32'h00000001;

        lut_in_a[22] = 32'h00000007;
        lut_in_b[22] = 32'h00000003;
        lut_result[22] = 32'h00000000;

        lut_in_a[23] = 32'hffffffff;
        lut_in_b[23] = 32'h7fffffff;
        lut_result[23] = 32'h00000000;

        #4;

        $display("\n\n\t\t\t\t----==== XOR ====----");
        $display("\t\ttime\tin_a,\t\tin_b,\t\tout,\t\tResult");
        funct3 = 4;
        funct7_4 = 0;
        alu_en = 1;
        alu_imm = 0;

        lut_in_a[24] = 32'hff00ff00;
        lut_in_b[24] = 32'hf00ff00f;
        lut_result[24] = 32'h0f0f0f0f;

        lut_in_a[25] = 32'h0ff00ff0;
        lut_in_b[25] = 32'hff00ff00;
        lut_result[25] = 32'hf0f0f0f0;

        lut_in_a[26] = 32'h00ff00ff;
        lut_in_b[26] = 32'h0ff00ff0;
        lut_result[26] = 32'h0f0f0f0f;

        lut_in_a[27] = 32'hf00ff00f;
        lut_in_b[27] = 32'h00ff00ff;
        lut_result[27] = 32'hf0f0f0f0;

        #4;

        $display("\n\n\t\t\t\t----==== SRL ====----");
        $display("\t\ttime\tin_a,\t\tin_b,\t\tout,\t\tResult");
        funct3 = 5;
        funct7_4 = 0;
        alu_en = 1;
        alu_imm = 0;

        lut_in_a[28] = 32'h80000001;
        lut_in_b[28] = 32'd0;
        lut_result[28] = 32'h80000001;

        lut_in_a[29] = 32'h80000001;
        lut_in_b[29] = 32'd1;
        lut_result[29] = 32'h40000000;

        lut_in_a[30] = 32'h80000001;
        lut_in_b[30] = 32'd14;
        lut_result[30] = 32'h00020000;

        lut_in_a[31] = 32'h80000001;
        lut_in_b[31] = 32'd31;
        lut_result[31] = 32'h00000001;

        #4;

        $display("\n\n\t\t\t\t----==== SRA ====----");
        $display("\t\ttime\tin_a,\t\tin_b,\t\tout,\t\tResult");
        funct3 = 5;
        funct7_4 = 1;
        alu_en = 1;
        alu_imm = 0;

        lut_in_a[32] = 32'h80000001;
        lut_in_b[32] = 32'd0;
        lut_result[32] = 32'h80000001;

        lut_in_a[33] = 32'h80000001;
        lut_in_b[33] = 32'd1;
        lut_result[33] = 32'hC0000000;

        lut_in_a[34] = 32'h40000001;
        lut_in_b[34] = 32'd30;
        lut_result[34] = 32'h00000001;

        lut_in_a[35] = 32'h80000001;
        lut_in_b[35] = 32'd30;
        lut_result[35] = 32'hFFFFFFFE;

        #4;

        $display("\n\n\t\t\t\t----==== OR ====----");
        $display("\t\ttime\tin_a,\t\tin_b,\t\tout,\t\tResult");
        funct3 = 6;
        funct7_4 = 0;
        alu_en = 1;
        alu_imm = 0;

        lut_in_a[36] = 32'hff00ff00;
        lut_in_b[36] = 32'h0f0f0f0f;
        lut_result[36] = 32'hff0fff0f;

        lut_in_a[37] = 32'h0ff00ff0;
        lut_in_b[37] = 32'hf0f0f0f0;
        lut_result[37] = 32'hfff0fff0;

        lut_in_a[38] = 32'h00ff00ff;
        lut_in_b[38] = 32'h0f0f0f0f;
        lut_result[38] = 32'h0fff0fff;

        lut_in_a[39] = 32'hf00ff00f;
        lut_in_b[39] = 32'hf0f0f0f0;
        lut_result[39] = 32'hf0fff0ff;

        #4;

        $display("\n\n\t\t\t\t----==== AND ====----");
        $display("\t\ttime\tin_a,\t\tin_b,\t\tout,\t\tResult");
        funct3 = 7;
        funct7_4 = 0;
        alu_en = 1;
        alu_imm = 0;

        lut_in_a[40] = 32'hff00ff00;
        lut_in_b[40] = 32'h0f0f0f0f;
        lut_result[40] = 32'h0f000f00;

        lut_in_a[41] = 32'h0ff00ff0;
        lut_in_b[41] = 32'hf0f0f0f0;
        lut_result[41] = 32'h00f000f0;

        lut_in_a[42] = 32'h00ff00ff;
        lut_in_b[42] = 32'h0f0f0f0f;
        lut_result[42] = 32'h000f000f;

        lut_in_a[43] = 32'hf00ff00f;
        lut_in_b[43] = 32'hf0f0f0f0;
        lut_result[43] = 32'hf000f000;

        #4;

        $display("\n\n\t\t\t\t----==== NONE ====----");
        $display("\t\ttime\tin_a,\t\tin_b,\t\tout,\t\tResult");
        funct3 = 7;
        funct7_4 = 1;
        alu_en = 0;
        alu_imm = 1;

        lut_in_a[44] = 32'd0;
        lut_in_b[44] = 32'd0;
        lut_result[44] = 32'd0;

        lut_in_a[45] = 32'd1;
        lut_in_b[45] = 32'd1;
        lut_result[45] = 32'd2;

        lut_in_a[46] = 32'd3;
        lut_in_b[46] = 32'd7;
        lut_result[46] = 32'd10;

        lut_in_a[47] = 32'h00000000;
        lut_in_b[47] = 32'hffff8000;
        lut_result[47] = 32'hffff8000;

        #4 $finish;

    end

endmodule
