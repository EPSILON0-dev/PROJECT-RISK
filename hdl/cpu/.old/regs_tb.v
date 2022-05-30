`include "../regs.v"
//`define DUMP

module regs_tb;

    /////////////////////////////////////////////////////////////////////////
    // Enable dump file if defined
    /////////////////////////////////////////////////////////////////////////
    `ifdef DUMP
    initial begin
        $dumpfile("regs.vcd");
        $dumpvars(0, DUT);
    end
    `endif

    /////////////////////////////////////////////////////////////////////////
    // Enable monitoring
    /////////////////////////////////////////////////////////////////////////
    initial begin
        $display("\tclk\tWrite\t\t\tRead 1\t\t\tRead 2");
        $monitor("\t%b,\t%h,\t%h,\t%h,\t%h,\t%h,\t%h",
            clk, addr_wr, dat_wr, addr_rd_a, dat_rd_a, addr_rd_b, dat_rd_b);
    end


    /////////////////////////////////////////////////////////////////////////
    // Device under test
    /////////////////////////////////////////////////////////////////////////
    reg         clk;
    reg         we;
    reg  [ 4:0] addr_rd_a;
    reg  [ 4:0] addr_rd_b;
    reg  [ 4:0] addr_wr;
    reg  [31:0] dat_wr;
    wire [31:0] dat_rd_a;
    wire [31:0] dat_rd_b;

    regs DUT (
        .i_clk       (clk),
        .i_we        (we),
        .i_addr_rd_a (addr_rd_a),
        .i_addr_rd_b (addr_rd_b),
        .i_addr_wr   (addr_wr),
        .i_dat_wr    (dat_wr),
        .o_dat_rd_a  (dat_rd_a),
        .o_dat_rd_b  (dat_rd_b)
    );


    /////////////////////////////////////////////////////////////////////////
    // Clock
    /////////////////////////////////////////////////////////////////////////
    always #1 clk = !clk;


    /////////////////////////////////////////////////////////////////////////
    // Test case
    /////////////////////////////////////////////////////////////////////////
    initial begin
        we = 1'b1;
        clk = 1'b0;
        for (integer i = 0; i < 64; i++) begin
            addr_rd_a = i[4:0];
            addr_rd_b = i[4:0] - 1;
            addr_wr   = i[4:0];
            dat_wr    = {3'b000, i[4:0], 16'h5555, 3'b000, i[4:0]};
            #2;
        end
        $finish;
    end


endmodule
