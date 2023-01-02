`include "../cpu/cpu.v"
`include "../peripheral/uart/uart_regs.v"

`define BRAM(name, i)                   \
  RAMB16BWER #(                         \
      .SIM_DEVICE    ("SPARTAN6"),      \
      .DATA_WIDTH_A  (2),               \
      .DATA_WIDTH_B  (2),               \
      .DOA_REG       (0),               \
      .DOB_REG       (0),               \
      .INIT_A        (36'h000000000),   \
      .INIT_B        (36'h000000000),   \
      .WRITE_MODE_A  ("WRITE_FIRST"),   \
      .WRITE_MODE_B  ("WRITE_FIRST")    \
    ) name (                            \
      .ADDRA  (bram_a_addr),            \
      .ADDRB  (bram_b_addr),            \
      .CLKA   (!clk),                   \
      .CLKB   (!clk),                   \
      .DIA    (2'b00),                  \
      .DIB    (bram_b_in[i*2+1:i*2]),   \
      .DOA    (bram_a_out[i*2+1:i*2]),  \
      .DOB    (bram_b_out[i*2+1:i*2]),  \
      .ENA    (1'b1),                   \
      .ENB    (1'b1),                   \
      .REGCEA (1'b0),                   \
      .REGCEB (1'b0),                   \
      .RSTA   (1'b0),                   \
      .RSTB   (1'b0),                   \
      .WEA    (1'b0),                   \
      .WEB    (bram_b_wr[i/4])          \
    );

module top (
  input CLK_100MHz,
  input UART_RX,
  output UART_TX,
  input [5:0] Switch,
  input [7:0] DPSwitch,
  output [7:0] LED
);

  reg [7:0] boot_reset = 8'hFF;
  reg reset;

  reg [31:0] counter = 0;
  reg clk = 0;

  wire [13:0] bram_a_addr;
  wire [13:0] bram_b_addr;
  wire [31:0] bram_b_in;
  wire [31:0] bram_a_out;
  wire [31:0] bram_b_out;
  wire [ 3:0] bram_b_wr;
  wire bram_en;

  wire [31:0] cpu_i_addr;
  wire [31:0] cpu_i_data_in;
  wire [31:0] cpu_d_addr;
  wire [31:0] cpu_d_data_in;
  wire [31:0] cpu_d_data_out;
  wire [ 3:0] cpu_d_data_wr;
  wire        cpu_d_data_rd;

  wire [31:0] io_out;
  wire [31:0] uart_out;
  reg [7:0] led_reg;
  wire led_en;
  wire uart_en;

  // Clocking stuff
  always @(posedge CLK_100MHz) begin
    if (counter == 0) begin
      counter <= 0;
      clk <= !clk;
    end else begin
      counter <= counter + 1;
    end
  end

  // Reset stuff
  always @(posedge clk) begin
    if (|boot_reset) begin
      boot_reset <= boot_reset - 1;
    end
    reset <= !Switch[0] || |boot_reset;
  end

  // Memory stuff
  `BRAM(bram0, 15)
  `BRAM(bram1, 14)
  `BRAM(bram2, 13)
  `BRAM(bram3, 12)
  `BRAM(bram4, 11)
  `BRAM(bram5, 10)
  `BRAM(bram6,  9)
  `BRAM(bram7,  8)
  `BRAM(bram8,  7)
  `BRAM(bram9,  6)
  `BRAM(bram10, 5)
  `BRAM(bram11, 4)
  `BRAM(bram12, 3)
  `BRAM(bram13, 2)
  `BRAM(bram14, 1)
  `BRAM(bram15, 0)

  assign bram_a_addr = { cpu_i_addr[14:2], 1'b0 };
  assign bram_b_addr = { cpu_d_addr[14:2], 1'b0 };
  assign bram_b_in = cpu_d_data_out;
  assign bram_b_wr = cpu_d_data_wr & {4{bram_en}};
  assign bram_en = (cpu_d_addr < 32'h00008000);

  // CPU stuff
  cpu cpu_i (
    .i_clk       (clk),
    .i_clk_ce    (1'b1),
    .i_rst       (reset),
    .o_addr_i    (cpu_i_addr),
    .i_data_in_i (cpu_i_data_in),
    .o_addr_d    (cpu_d_addr),
    .i_data_rd_d (cpu_d_data_in),
    .o_data_wr_d (cpu_d_data_out),
    .o_wr_d      (cpu_d_data_wr),
    .o_rd_d      (cpu_d_data_rd)
  );

  assign cpu_i_data_in = bram_a_out;
  assign cpu_d_data_in = (bram_en) ? bram_b_out : io_out;

  // IO stuff
  assign io_out = uart_en ? uart_out : {19'd0, Switch[5:1], DPSwitch};

  assign led_en = (cpu_d_addr == 32'h00008010);
  always @(negedge clk) begin
    if (cpu_d_data_wr[0] && led_en) begin
      led_reg <= cpu_d_data_out[7:0];
    end
  end

  assign uart_en = (cpu_d_addr[31:4] == 28'h0000800);
  uart_regs uart_regs_i (
    .i_clk      (!clk),
    .i_rst      (reset),
    .i_wr       (&cpu_d_data_wr),
    .i_rd       (cpu_d_data_rd),
    .i_cs       (uart_en),
    .i_addr     (cpu_d_addr[3:2]),
    .i_data_in  (cpu_d_data_out),
    .o_data_out (uart_out),
    .o_tx       (UART_TX),
    .i_rx       (UART_RX)
);

  assign LED = led_reg;

endmodule
