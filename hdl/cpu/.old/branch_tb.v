`include "../branch.v"
//`define DUMP

module branch_tb;

    /////////////////////////////////////////////////////////////////////////
    // Enable dump file if defined
    /////////////////////////////////////////////////////////////////////////
    `ifdef DUMP
    initial begin
        $dumpfile("branch.vcd");
        $dumpvars(0, DUT);
    end
    `endif

    /////////////////////////////////////////////////////////////////////////
    // Enable monitoring
    /////////////////////////////////////////////////////////////////////////
    initial begin
        $display("\tdat_a,\t\tdat_b,\t\tfunct3,\topcode,\tbranch,\tResult");
        $monitor("\t%h,\t%h,\t%h,\t%h,\t%h,\t%b",
            dat_a, dat_b, funct3, opcode, branch_en, result);
    end


    /////////////////////////////////////////////////////////////////////////
    // Device under test
    /////////////////////////////////////////////////////////////////////////
    reg  [31:0] dat_a;
    reg  [31:0] dat_b;
    reg  [ 2:0] funct3;
    reg  [ 4:0] opcode;
    wire        branch_en;
    wire        result;

    branch DUT (
        .i_dat_a     (dat_a),
        .i_dat_b     (dat_b),
        .i_funct3    (funct3),
        .i_opcode    (opcode),
        .o_branch_en (branch_en)
    );

    // verilator lint_off WIDTH
    assign result = $time ^ branch_en;
    // verilator lint_on WIDTH


    /////////////////////////////////////////////////////////////////////////
    // Test case
    /////////////////////////////////////////////////////////////////////////
    initial begin
        dat_a = 0;
        dat_b = 0;
        funct3 = 0;
        opcode = 0;

        // Jumps
            opcode = 5'b11001;
        #1  opcode = 5'b11111;
        #1  opcode = 5'b11011;
        #1  opcode = 5'b00000;

        // Equal
        #1  opcode = 5'b11000;
            funct3 = 3'b000;
            dat_a = 32'h55aa55aa;
            dat_b = 32'h55aa55aa;
        #1  funct3 = 3'b000;
            dat_a = 32'h55aa55aa;
            dat_b = 32'haa55aa55;

        // Not Equal
        #1  funct3 = 3'b001;
            dat_a = 32'h55aa55aa;
            dat_b = 32'haa55aa55;
        #1  funct3 = 3'b001;
            dat_a = 32'h55aa55aa;
            dat_b = 32'h55aa55aa;

        // Lower Signed
        #1  funct3 = 3'b100;
            dat_a = 32'hffffffff;
            dat_b = 32'h00000001;
        #1  funct3 = 3'b100;
            dat_a = 32'h00000055;
            dat_b = 32'h00000055;

        // Greater Equal Signed
        #1  funct3 = 3'b101;
            dat_a = 32'h00000001;
            dat_b = 32'h00000001;
        #1  funct3 = 3'b101;
            dat_a = 32'hffffffff;
            dat_b = 32'h00000001;

        // Lower Unsigned
        #1  funct3 = 3'b110;
            dat_a = 32'h00000001;
            dat_b = 32'hffffffff;
        #1  funct3 = 3'b110;
            dat_a = 32'hffffffff;
            dat_b = 32'h00000001;

        // Greater Equal Unsigned
        #1  funct3 = 3'b111;
            dat_a = 32'hffffffff;
            dat_b = 32'h00000001;
        #1  funct3 = 3'b111;
            dat_a = 32'h00000001;
            dat_b = 32'hffffffff;

        #1  $finish;
    end


endmodule
