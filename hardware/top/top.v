`include "../cpu/cpu.v"
`include "../peripheral/uart/uart_regs.v"
`include "../peripheral/boot_rom/boot_rom.v"

module top (
  input CLK_100MHz,
  input UART_RX,
  output UART_TX,
  input [5:0] Switch,
  input [7:0] DPSwitch,
  output [7:0] LED
);

  // Reset stuff
  wire reset = !Switch[0];

  // Clocking stuff
  reg [31:0] counter = 0;
  reg clk = 0;
  always @(posedge CLK_100MHz) begin
    if (counter == 0) begin
      counter <= 0;
      clk <= !clk;
    end else begin
      counter <= counter + 1;
    end
  end

  // CPU stuff
  wire [31:0] cpu_i_addr;
  wire [31:0] cpu_i_data_in;
  wire [31:0] cpu_d_addr;
  wire [31:0] cpu_d_data_in;
  wire [31:0] cpu_d_data_out;
  wire [ 3:0] cpu_d_data_wr;
  wire        cpu_d_data_rd;

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

  // Memory stuff
  (* ram_style = "block" *)
  reg   [7:0] ram_array_3 [0:8191];
  reg   [7:0] ram_array_2 [0:8191];
  reg   [7:0] ram_array_1 [0:8191];
  reg   [7:0] ram_array_0 [0:8191];
  wire [12:0] ram_addr_i;
  wire [12:0] ram_addr_d;
  wire [31:0] ram_data_in_d;
  reg  [31:0] ram_data_out_i;
  reg  [31:0] ram_data_out_d;
  wire  [3:0] ram_wr_d;
  wire        ram_en;

  always @(negedge clk) begin
    ram_data_out_i <= {
      ram_array_3[ram_addr_i],
      ram_array_2[ram_addr_i],
      ram_array_1[ram_addr_i],
      ram_array_0[ram_addr_i]
    };

    ram_data_out_d <= {
      ram_array_3[ram_addr_d],
      ram_array_2[ram_addr_d],
      ram_array_1[ram_addr_d],
      ram_array_0[ram_addr_d]
    };

    if (ram_wr_d[0] && ram_en) begin
      ram_array_0[ram_addr_d] <= ram_data_in_d[7:0];
    end

    if (ram_wr_d[1] && ram_en) begin
      ram_array_1[ram_addr_d] <= ram_data_in_d[15:8];
    end

    if (ram_wr_d[2] && ram_en) begin
      ram_array_2[ram_addr_d] <= ram_data_in_d[23:16];
    end

    if (ram_wr_d[3] && ram_en) begin
      ram_array_3[ram_addr_d] <= ram_data_in_d[31:24];
    end
  end

  assign ram_addr_i = cpu_i_addr[14:2];
  assign ram_addr_d = cpu_d_addr[14:2];
  assign ram_en = (cpu_d_addr < 32'h00008000);
  assign ram_wr_d = cpu_d_data_wr;
  assign ram_data_in_d = cpu_d_data_out;

  // bootloader stuff
  wire [31:0] bld_data;
  boot_rom boot_rom_i (
    .i_clk  (!clk),
    .i_addr (cpu_i_addr[10:2]),
    .o_data (bld_data)
  );
  wire bld_en = (cpu_i_addr >= 32'h00010000 && cpu_i_addr < 32'h00010800);

  // IO stuff
  wire [31:0] io_out;
  wire [31:0] uart_out;
  reg [7:0] led_reg;
  wire led_en;
  wire uart_en;

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

  // CPU bus stuff
  assign io_out = uart_en ? uart_out : {19'd0, Switch[5:1], DPSwitch};
  assign cpu_d_data_in = ram_en ? ram_data_out_d : io_out;
  assign cpu_i_data_in = bld_en ? bld_data : ram_data_out_i;

endmodule
