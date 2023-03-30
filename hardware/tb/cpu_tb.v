/****************************************************************************
 * Copyright 2023 Lukasz Forenc
 *
 * File: cpu_tb.v
 *
 * This is a CPU test bench for testing the CPU core, 32kB of memory is
 * connected at addresses from 0x0000 to 0x7FFF, all CPU activitiy is dumped
 * to the LOG_FILE, initial memory data is read from MEM_FILE, execution is
 * stopped if the program counter reaches 0x10000 or after KILL_TIME cycles.
 ***************************************************************************/
`define LOG_FILE "cpu_log.vcd"
`define MEM_FILE "cpu.mem"
`define KILL_TIME #10000

`include "../cpu/cpu.v"

module cpu_tb;

  // Dump file
  initial begin
    $dumpfile(`LOG_FILE);
    $dumpvars(0, cpu_i);
  end

  // CPU
  reg         i_clk;
  reg         i_rst;
  reg         i_clk_ce;
  reg  [31:0] i_data_in_i;
  reg  [31:0] i_data_rd_d;
  wire [ 3:0] o_wr_d;
  wire        o_rd_d;
  wire [31:0] o_addr_i;
  wire [31:0] o_addr_d;
  wire [31:0] o_data_wr_d;

  // verilator lint_off pinmissing
  cpu cpu_i (
    .i_clk       (i_clk),
    .i_rst       (i_rst),
    .i_clk_ce    (i_clk_ce),
    .o_addr_i    (o_addr_i),
    .i_data_in_i (i_data_in_i),
    .o_addr_d    (o_addr_d),
    .i_data_rd_d (i_data_rd_d),
    .o_wr_d      (o_wr_d),
    .o_rd_d      (o_rd_d),
    .o_data_wr_d (o_data_wr_d)
  );
  // verilator lint_on pinmissing

  // Clock
  initial   i_clk = 0;
  always #1 i_clk = !i_clk;
  // always #4 i_clk_ce = !i_clk_ce;

  // Constant Signals
  initial begin
    i_rst = 1;
    i_clk_ce = 1;
    i_data_rd_d = 0;
    #10 i_rst = 0;

    `KILL_TIME $display("Killed by timeout"); $finish;
  end

  // Data memory
  reg [31:0] memory_array [0:8191];
  initial begin
    $readmemh("cpu.mem", memory_array);
  end

  // Memory process
  always @(negedge i_clk) begin

    // Instruction read
    i_data_in_i <= i_read_data;

    // Data read
    if (o_rd_d) begin
      $display("R %d (%h)", d_write_data, o_addr_d);
      i_data_rd_d <= d_read_data;
    end else begin
      i_data_rd_d <= 0;
    end

    // Data write
    if (|o_wr_d) begin
      $display("W %d (%h)", d_write_data, o_addr_d);
      memory_array[o_addr_d[14:2]] <= d_write_data;
    end
  end

  // Additional memory signals
  wire [31:0] i_read_data = memory_array[o_addr_i[14:2]];
  wire [31:0] d_read_data = memory_array[o_addr_d[14:2]];
  wire [31:0] d_write_data = {
    o_wr_d[3]? o_data_wr_d[31:24] : d_read_data[31:24],
    o_wr_d[2]? o_data_wr_d[23:16] : d_read_data[23:16],
    o_wr_d[1]? o_data_wr_d[15:8 ] : d_read_data[15:8 ],
    o_wr_d[0]? o_data_wr_d[ 7:0 ] : d_read_data[ 7:0 ]
  };

  // Stop on kill address
  always @(posedge i_clk) begin
    if (o_addr_i == 32'h00010000) begin
      $display("Killed by reaching kill address %d", $time / 2 + 1); $finish;
    end
  end

endmodule
