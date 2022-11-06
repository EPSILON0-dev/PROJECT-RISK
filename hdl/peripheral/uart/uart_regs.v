/**
 *
 * 0 - Clock register
 * [31:16] - unused
 * [15:0] - clock division (rw0)
 *
 * 1 - Configuration register
 * [31:9] - unused
 * [8] - rx_clear bit (w)
 * [7] - tx_clear bit (w)
 * [6:5] - length (rw2)
 * [4] - stop bits (rw0)
 * [3] - odd parity (rw0)
 * [2] - parity (rw0)
 * [1] - rx enable (rw0)
 * [0] - tx enable (rw0)
 *
 * 2 - Status register
 * [31:8] - unused
 * [7] - rx buffer full (r)
 * [6] - rx buffer half (r)
 * [5] - rx buffer empty (r)
 * [4] - tx buffer full (r)
 * [3] - tx buffer half (r)
 * [2] - tx buffer empty (r)
 * [1] - overrun err (r)
 * [0] - parity err (r)
 *
 * 3 - Data io register
 * [31:9] - unused
 * [8:0] - tx/rx data (rw) (like AVR)
 */
`include "uart.v"

module uart_regs(
  // verilator lint_off unused
  input         i_clk,
  input         i_rst,

  input         i_wr,
  input         i_rd,
  input         i_cs,
  input  [ 1:0] i_addr,
  input  [31:0] i_data_in,
  output [31:0] o_data_out,

  output        o_tx,
  input         i_rx
  // verilator lint_on unused
);

  localparam [1:0]
    A_CLOCK  = 0,
    A_CONFIG = 1,
    A_STATUS = 2,
    A_DATA   = 3;

  reg [15:0] clk_div_reg = 0;
  reg [ 6:0] config_reg  = 0;

  wire [8:0] read_data;
  wire       overrun_err;
  wire       parity_err;
  wire       txbuf_empty;
  wire       txbuf_half;
  wire       txbuf_full;
  wire       rxbuf_empty;
  wire       rxbuf_half;
  wire       rxbuf_full;

  wire clock_adr;
  wire config_adr;
  wire status_adr;
  wire data_adr;
  wire txwr;
  wire rxrd;
  wire clear_txbuf;
  wire clear_rxbuf;
  wire clear_err;

  wire [7:0] status_reg;

  reg [31:0] data_out;

  always @(posedge i_clk) begin
    if (i_rst) begin
      clk_div_reg <= 0;
    end else if (i_cs && i_wr && clock_adr) begin
      clk_div_reg <= i_data_in[15:0];
    end
  end

  always @(posedge i_clk) begin
    if (i_rst) begin
      config_reg <= 0;
    end else if (i_cs && i_wr && config_adr) begin
      config_reg <= i_data_in[6:0];
    end
  end

  uart uart_i (
  .i_clk         (i_clk),
  .i_rst         (i_rst),
  .i_clk_div     (clk_div_reg),
  .i_txen        (config_reg[0]),
  .i_rxen        (config_reg[1]),
  .i_length      (config_reg[6:5]),
  .i_stop2       (config_reg[4]),
  .i_parity      (config_reg[2]),
  .i_odd         (config_reg[3]),
  .i_rst_err     (clear_err),
  .i_clear_txbuf (clear_txbuf),
  .i_clear_rxbuf (clear_rxbuf),
  .i_data_in     (i_data_in[8:0]),
  .o_data_out    (read_data),
  .i_txwr        (txwr),
  .i_rxrd        (rxrd),
  .o_overrun_err (overrun_err),
  .o_parity_err  (parity_err),
  .o_txbuf_empty (txbuf_empty),
  .o_txbuf_half  (txbuf_half),
  .o_txbuf_full  (txbuf_full),
  .o_rxbuf_empty (rxbuf_empty),
  .o_rxbuf_half  (rxbuf_half),
  .o_rxbuf_full  (rxbuf_full),
  .o_tx          (o_tx),
  .i_rx          (i_rx)
  );

  assign clock_adr  = (i_addr == A_CLOCK);
  assign config_adr = (i_addr == A_CONFIG);
  assign status_adr = (i_addr == A_STATUS);
  assign data_adr   = (i_addr == A_DATA);

  assign txwr        = i_cs && i_wr && data_adr;
  assign rxrd        = i_cs && i_rd && data_adr;
  assign clear_txbuf = i_cs && i_wr && config_adr && i_data_in[7];
  assign clear_rxbuf = i_cs && i_wr && config_adr && i_data_in[8];
  assign clear_err   = i_cs && i_rd && status_adr;

  assign status_reg = {
    rxbuf_full, rxbuf_half, rxbuf_empty,
    txbuf_full, txbuf_half, txbuf_empty,
    overrun_err, parity_err
  };

  always @* begin
    case (i_addr)
      A_CLOCK:  data_out = { 16'd0, clk_div_reg };
      A_CONFIG: data_out = { 25'd0, config_reg };
      A_STATUS: data_out = { 24'd0, status_reg };
      A_DATA:   data_out = { 23'd0, read_data };
    endcase
  end

  assign o_data_out = data_out;

endmodule
