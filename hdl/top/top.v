`include "../cpu/cpu.v"

module top (
  input CLK_100MHz,
  input [1:0] Switch,
  output [7:0] LED
);

  // Clk generation
  reg [31:0] counter = 0;
  reg clk = 0;
  always @(posedge CLK_100MHz) begin
    if (counter == 5_000_000) begin
      counter <= 0;
      clk <= !clk;
    end else begin
      counter <= counter + 1;
    end

  end

  wire [3:0] memory_address;
  wire [31:0] memory [0:15];
  reg [31:0] memory_out = 0;
  assign memory[0]  = 32'h00000093;
  assign memory[1]  = 32'h00a00113;
  assign memory[2]  = 32'h00108093;
  assign memory[3]  = 32'h00009073;
  assign memory[4]  = 32'h00209463;
  assign memory[5]  = 32'hfedff06f;
  assign memory[6]  = 32'hfe0008e3;
  assign memory[7]  = 32'h00000000;
  assign memory[8]  = 32'h00000000;
  assign memory[9]  = 32'h00000000;
  assign memory[10] = 32'h00000000;
  assign memory[11] = 32'h00000000;
  assign memory[12] = 32'h00000000;
  assign memory[13] = 32'h00000000;
  assign memory[14] = 32'h00000000;
  assign memory[15] = 32'h00000000;
  always @(negedge clk) begin
    memory_out <= memory[memory_address];
  end

  wire csr_wr;
  wire [31:0] csr_wr_data;
  wire [31:0] cpu_addr;
  cpu cpu_i (
    .i_clk(clk),
    .i_clk_ce(Switch[1]),
    .i_rst(!Switch[0]),

    .o_csr_addr(),
    .i_csr_rd_data(0),
    .o_csr_wr_data(csr_wr_data),
    .o_csr_wr(csr_wr),
    .o_csr_rd(),

    .o_addr_i(cpu_addr),
    .i_data_in_i(memory_out),

    .o_addr_d(),
    .i_data_rd_d(0),
    .o_data_wr_d(),
    .o_wr_d(),
    .o_rd_d()
  );
  assign memory_address = cpu_addr[5:2];

  reg [7:0] led_reg = 0;
  always @(negedge clk) begin
    if (csr_wr) begin
      led_reg <= csr_wr_data[7:0];
    end
  end
  assign LED = led_reg;

endmodule
