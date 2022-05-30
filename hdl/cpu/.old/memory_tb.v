`include "../memory.v"
//`define DUMP

module memory_tb;

    /////////////////////////////////////////////////////////////////////////
    // Enable dump file if defined
    /////////////////////////////////////////////////////////////////////////
    `ifdef DUMP
    initial begin
        $dumpfile("memory.vcd");
        $dumpvars(0, DUT);
    end
    `endif

    /////////////////////////////////////////////////////////////////////////
    // Enable monitoring
    /////////////////////////////////////////////////////////////////////////
    initial begin
        $monitor("\t%h,\t%h,\t%h,\t%h,\t%h,\t%h,\t%b\t%b",
            data_rd_in, data_wr_in, data_rd_out, data_wr_out,
            shift, length, signed_rd, we);
    end


    /////////////////////////////////////////////////////////////////////////
    // Device under test
    /////////////////////////////////////////////////////////////////////////
    reg  [31:0] data_rd_in;
    reg  [31:0] data_wr_in;
    reg  [ 1:0] shift;
    reg  [ 1:0] length;
    reg         signed_rd;
    wire [31:0] data_rd_out;
    wire [31:0] data_wr_out;
    wire  [3:0] we;

    memory DUT (
        .i_data_rd   (data_rd_in),
        .i_data_wr   (data_wr_in),
        .i_shift     (shift),
        .i_length    (length),
        .i_signed_rd (signed_rd),
        .o_data_rd   (data_rd_out),
        .o_data_wr   (data_wr_out),
        .o_we        (we)
    );


    /////////////////////////////////////////////////////////////////////////
    // Test case
    /////////////////////////////////////////////////////////////////////////
    initial begin

        // Normal read and write
        $display("\n\t\t\t\t----==== Normal ====----");
        $display("\trdin\t\twrin\t\trdout\t\twrout\t\tshift\tlength\tsigned\twe");
        data_rd_in = 32'h8055aa01;
        data_wr_in = 32'h8055aa01;
        shift = 2'b00;
        length = 2'b10;
        signed_rd = 1'b0; #1;

        // Lengths
        $display("\n\t\t\t\t----==== Lengths ====----");
        $display("\trdin\t\twrin\t\trdout\t\twrout\t\tshift\tlength\tsigned\twe");
        length = 2'b00; shift = 2'b00; #1;
        length = 2'b01; shift = 2'b00; #1;

        // Shifts
        $display("\n\t\t\t\t----==== Shifts ====----");
        $display("\trdin\t\twrin\t\trdout\t\twrout\t\tshift\tlength\tsigned\twe");
        length = 2'b10; shift = 2'b01; #1;
        length = 2'b10; shift = 2'b10; #1;
        length = 2'b10; shift = 2'b11; #1;

        // Length + shifts
        $display("\n\t\t\t    ----==== Lengths + Shifts ====----");
        $display("\trdin\t\twrin\t\trdout\t\twrout\t\tshift\tlength\tsigned\twe");
        length = 2'b00; shift = 2'b01; #1;
        length = 2'b00; shift = 2'b10; #1;
        length = 2'b00; shift = 2'b11; #1;
        length = 2'b01; shift = 2'b01; #1;
        length = 2'b01; shift = 2'b10; #1;
        length = 2'b01; shift = 2'b11; #1;

        // Sign extend
        $display("\n\t\t\t      ----==== Sign Extend ====----");
        $display("\trdin\t\twrin\t\trdout\t\twrout\t\tshift\tlength\tsigned\twe");
        data_rd_in = 32'h00008080;
        data_wr_in = 32'h00000000;
        length = 2'b00; shift = 2'b00; signed_rd = 0; #1;
        length = 2'b00; shift = 2'b00; signed_rd = 1; #1;
        length = 2'b01; shift = 2'b00; signed_rd = 0; #1;
        length = 2'b01; shift = 2'b00; signed_rd = 1; #1;
    end


endmodule
