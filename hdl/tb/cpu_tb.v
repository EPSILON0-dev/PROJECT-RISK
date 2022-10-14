`include "../cpu/cpu.v"

module cpu_tb;

  ///////////////////////////////////////////////////////////////////////////
  // Enable dump file if defined
  ///////////////////////////////////////////////////////////////////////////
  initial begin
    $dumpfile("cpu_log.vcd");
    $dumpvars(0, DUT);
  end


  ///////////////////////////////////////////////////////////////////////////
  // Device under test
  ///////////////////////////////////////////////////////////////////////////
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
  cpu DUT (
    .i_clk       (i_clk),
    .i_rst       (i_rst),
    .i_clk_ce   (i_clk_ce),
    .o_addr_i    (o_addr_i),
    .i_data_in_i (i_data_in_i),
    .o_addr_d    (o_addr_d),
    .i_data_rd_d (i_data_rd_d),
    .o_wr_d      (o_wr_d),
    .o_rd_d      (o_rd_d),
    .o_data_wr_d (o_data_wr_d)
  );
  // verilator lint_on pinmissing

  ///////////////////////////////////////////////////////////////////////////
  // Clock
  ///////////////////////////////////////////////////////////////////////////
  initial   i_clk = 0;
  always #1 i_clk = !i_clk;
  // always #4 i_clk_ce = !i_clk_ce;


  ///////////////////////////////////////////////////////////////////////////
  // Constant Signals
  ///////////////////////////////////////////////////////////////////////////
  initial begin
    i_rst = 1;
    i_clk_ce = 1;
    i_data_rd_d = 0;
    #10 i_rst = 0;

    #10000 $display("Killed by timeout"); $finish;
  end


  ///////////////////////////////////////////////////////////////////////////
  // Program memory
  ///////////////////////////////////////////////////////////////////////////
  reg  [31:0] i_cache_array [0:8191];
  initial begin
    $readmemh("cpu.mem", i_cache_array);
  end

  always @(negedge i_clk) begin
    i_data_in_i <= i_cache_array[o_addr_i[14:2]];
  end


  ///////////////////////////////////////////////////////////////////////////
  // Data memory
  ///////////////////////////////////////////////////////////////////////////
  reg  [31:0] d_cache_array [0:8191];
  initial begin
    $readmemh("cpu.mem", d_cache_array);
  end

  always @(negedge i_clk) begin
    if (o_rd_d) begin
      i_data_rd_d <= d_read_data;
      $display("R %d (%h)", d_write_data, o_addr_d);
    end else begin
      i_data_rd_d <= 0;
    end
    if (|o_wr_d) begin
      $display("W %d (%h)", d_write_data, o_addr_d);
      d_cache_array[o_addr_d[14:2]] <= d_write_data;
    end
  end

  wire [31:0] d_read_data = d_cache_array[o_addr_d[14:2]];
  wire [31:0] d_write_data = {
    o_wr_d[3]? o_data_wr_d[31:24] : d_read_data[31:24],
    o_wr_d[2]? o_data_wr_d[23:16] : d_read_data[23:16],
    o_wr_d[1]? o_data_wr_d[15:8 ] : d_read_data[15:8 ],
    o_wr_d[0]? o_data_wr_d[ 7:0 ] : d_read_data[ 7:0 ]
  };


  /////////////////////////////////////////////////////////////////////////
  // Stop on kill address
  /////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin
    if (o_addr_i == 32'h00010000) begin
      $display("Killed by reaching kill address %d", $time / 2 + 1); $finish;
    end
  end


endmodule
