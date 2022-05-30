`include "../decoder.v"
//`define DUMP

module decoder_tb;

    /////////////////////////////////////////////////////////////////////////
    // Enable dump file if defined
    /////////////////////////////////////////////////////////////////////////
    `ifdef DUMP
    initial begin
        $dumpfile("decoder.vcd");
        $dumpvars(0, DUT);
    end
    `endif


    /////////////////////////////////////////////////////////////////////////
    // Enable monitoring
    /////////////////////////////////////////////////////////////////////////
    initial begin
        $display("\tOpcode_in\tImmediate");
        $monitor("\t%h,\t%h", opcode_in, immediate);
    end


    /////////////////////////////////////////////////////////////////////////
    // Device under test
    /////////////////////////////////////////////////////////////////////////
    // verilator lint_off unused
    reg  [31:0] opcode_in;
    wire [31:0] immediate;
    wire [ 4:0] opcode;
    wire [ 2:0] funct3;
    wire [ 6:0] funct7;
    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [ 4:0] rd;
    wire        hz_rsa;
    wire        hz_rsb;
    wire        alu_pc;
    wire        alu_imm;
    wire        alu_en;
    wire        ma_wr;
    wire        ma_rd;
    wire [ 1:0] wb_mux;
    wire        wb_en;
    // verilator lint_on unused

    decoder DUT (
        .i_opcode_in (opcode_in),
        .o_immediate (immediate),
        .o_opcode    (opcode),
        .o_funct3    (funct3),
        .o_funct7    (funct7),
        .o_rsa       (rs1),
        .o_rsb       (rs2),
        .o_rd        (rd),
        .o_hz_rsa    (hz_rsa),
        .o_hz_rsb    (hz_rsb),
        .o_alu_pc    (alu_pc),
        .o_alu_imm   (alu_imm),
        .o_alu_en    (alu_en),
        .o_ma_wr     (ma_wr),
        .o_ma_rd     (ma_rd),
        .o_wb_mux    (wb_mux),
        .o_wb_en     (wb_en)
    );


    /////////////////////////////////////////////////////////////////////////
    // Test Cases
    /////////////////////////////////////////////////////////////////////////
    initial begin
        opcode_in = 32'h55500003; #1; // load
        opcode_in = 32'haaa00003; #1; // load
        opcode_in = 32'h55500013; #1; // op-imm
        opcode_in = 32'haaa00013; #1; // op-imm
        opcode_in = 32'h55555017; #1; // auipc
        opcode_in = 32'haaaaa017; #1; // auipc
        opcode_in = 32'h54000aa3; #1; // store
        opcode_in = 32'haa000523; #1; // store
        opcode_in = 32'h00000033; #1; // op
        opcode_in = 32'h00000033; #1; // op
        opcode_in = 32'h55555037; #1; // lui
        opcode_in = 32'haaaaa037; #1; // lui
        opcode_in = 32'h54000a63; #1; // branch
        opcode_in = 32'haa0005e3; #1; // branch
        opcode_in = 32'h55500067; #1; // jalr
        opcode_in = 32'haaa00067; #1; // jalr
        opcode_in = 32'h5545506f; #1; // jal
        opcode_in = 32'haabaa06f; #1; // jal
        $finish;
    end

endmodule
