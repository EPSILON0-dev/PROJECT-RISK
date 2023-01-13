/****************************************************************************
 * Copyright 2022 Lukasz Forenc
 *
 * File: uart.v
 *
 * This file contains the UART transmitter and receiver buffers and the baud
 * rate generator.
 *
 * i_clk         - Clock input
 * i_rst         - Reset input
 * i_clk_div     - Clock division amoint
 *
 * i_length      - Receive data length (i_length + 6 is the actual length)
 * i_stop2       - Two stop bits enable
 * i_parity      - Parity bit enable
 * i_odd         - Odd parity enable
 *
 * i_rst_err     - Error clear input
 * i_clear_txbuf - Clear the transmitter buffer
 * i_clear_rxbuf - Clear the receiver buffer
 *
 * i_data_in     - Data input
 * o_data_out    - Data output
 * i_txwr        - Data write enable
 * i_rxrd        - Data read enable
 *
 * o_overrun_err - Overrun error (state of '0' in stop bits)
 * o_parity_err  - Parity error (sum of all ones not correct)
 *
 * o_txbuf_empty - Transmitter buffer is empty
 * o_txbuf_half  - Transmitter buffer is half full
 * o_txbuf_full  - Transmitter buffer is full
 * o_rxbuf_empty - Receiver buffer is empty
 * o_rxbuf_half  - Receiver buffer is half full
 * o_rxbuf_full  - Receiver buffer is full
 *
 * o_tx          - Transmitter output
 * i_rx          - Receiver input
 ***************************************************************************/
`include "baud_gen.v"
`include "tx.v"
`include "rx.v"

module uart(
  input         i_clk,
  input         i_rst,
  input  [15:0] i_clk_div,

  input         i_txen,
  input         i_rxen,

  input   [1:0] i_length,
  input         i_stop2,
  input         i_parity,
  input         i_odd,

  input         i_rst_err,
  input         i_clear_txbuf,
  input         i_clear_rxbuf,

  input   [8:0] i_data_in,
  output  [8:0] o_data_out,
  input         i_txwr,
  input         i_rxrd,

  output        o_overrun_err,
  output        o_parity_err,

  output        o_txbuf_empty,
  output        o_txbuf_half,
  output        o_txbuf_full,
  output        o_rxbuf_empty,
  output        o_rxbuf_half,
  output        o_rxbuf_full,

  output        o_tx,
  input         i_rx
);

  // Baud rate clock enable generator
  wire       ce_x8;
  wire       ce;

  // Transmiter buffer
  reg  [8:0] tx_buffer [0:15];
  reg  [4:0] tx_buff_cnt = 5'b01111;

  wire [8:0] tx_buff_data;
  wire       tx_ce;
  wire       tx_start;
  wire       tx_busy;
  wire       tx_buf_empty;
  wire       tx_buf_half;
  wire       tx_buf_full;

  // Receiver buffer
  reg  [8:0] rx_buffer [0:15];
  reg  [4:0] rx_buff_cnt = 5'b01111;
  reg  [8:0] rx_buff_data = 0;
  reg        rx_busy_prev = 0;

  wire [8:0] rx_data;
  wire       rx_buff_wr;
  wire       rx_buf_empty;
  wire       rx_buf_half;
  wire       rx_buf_full;
  wire       rx_ce;
  wire       rx_busy;

  /**
   * Baud rate generator generates 2 clock enable signals one faster (ce_x8)
   * used for receiver syncing (it's divided further inside the receiver) and
   * a slower signal used for transmitter.
   */
  uart_baud_gen uart_baud_gen_i (
    .i_clk     (i_clk),
    .i_rst     (i_rst),
    .i_clk_div (i_clk_div),
    .o_ce_x8   (ce_x8),
    .o_ce      (ce)
  );

  /**
   * Transmitter buffer, implemented as shift register and a counter register,
   * bit 4 of the counter is used as inverted buffer empty signal, when data
   * is loaded into the buffer counter changes state from 01111 (BIT4:0) to
   * 10000 (BIT4:1), data is sent out until bit 4 gets cleared.
   */
  always @(posedge i_clk) begin
    // If conditions for the buffer clear are met the counter is reset to
    // initial values.
    if (i_clear_txbuf || i_rst || !i_txen) begin
      tx_buff_cnt <= 5'b01111;
    end else begin
      if (i_txwr) begin
        // Shift the data into the buffer
        for (integer i = 0; i < 15; i = i + 1) begin
          tx_buffer[i + 1] <= tx_buffer[i];
        end
        tx_buffer[0] <= i_data_in;
        // Unless at this point the data is read from the buffer increment the
        // counter (if data is both read and written data is shifted but the
        // counter stays the same).
        if (!ce || !tx_start) begin
          tx_buff_cnt <= tx_buff_cnt + 1;
        end
      end else if (ce && tx_start) begin
        // If reading from the buffer and NOT writing to it decrement the cnt.
        tx_buff_cnt <= tx_buff_cnt - 1;
      end
    end
  end

  // Buffer data is just multiplexed from the shift register (internally it's
  // much more optimised than it looks)
  assign tx_buff_data = tx_buffer[tx_buff_cnt[3:0]];
  // Transimtter ce is global ce AND transmitter enable
  assign tx_ce = ce && i_txen;
  // If there's data in the buffer and transmitter isn't already busy start
  // the transmission
  assign tx_start = tx_buff_cnt[4] && !tx_busy;

  // Transmitter buffer fill signals
  assign tx_buf_empty = (tx_buff_cnt == 5'b01111);
  assign tx_buf_half  = (tx_buff_cnt >= 5'b11000);
  assign tx_buf_full  = (tx_buff_cnt == 5'b11111);

  // Transmitter instancing
  uart_tx tx_i (
    .i_clk    (i_clk),
    .i_ce     (tx_ce),
    .i_rst    (i_rst),
    .i_data   (tx_buff_data),
    .i_length (i_length),
    .i_stop2  (i_stop2),
    .i_parity (i_parity),
    .i_odd    (i_odd),
    .i_start  (tx_start),
    .o_tx     (o_tx),
    .o_busy   (tx_busy)
  );

  /**
   * Receiver buffer works just like the transmitter buffer, only real
   * difference being that the receiver dictates when the buffer is written
   * instead of the data bus.
   */
  always @(posedge i_clk) begin
    // If conditions for the buffer clear are met the counter is reset to
    // initial values.
    if (i_clear_rxbuf || i_rst || !i_rxen) begin
      rx_buff_cnt <= 5'b01111;
    end else begin
      if (rx_buff_wr) begin
        // Shift the data into the buffer
        for (integer i = 0; i < 15; i = i + 1) begin
          rx_buffer[i + 1] <= rx_buffer[i];
        end
        rx_buffer[0] <= rx_data;
        // Unless at R and W operation occured increment the counter.
        if (!i_rxrd || !rx_buff_cnt[4]) begin
          rx_buff_cnt <= rx_buff_cnt + 1;
        end
      end
      if (i_rxrd && rx_buff_cnt[4]) begin
        // Put the buffer data out on the data line
        rx_buff_data <= rx_buffer[rx_buff_cnt[3:0]];
        // Unless at R and W operation occured increment the counter.
        if (!rx_buff_wr) begin
          rx_buff_cnt <= rx_buff_cnt - 1;
        end
      end
    end
  end

  /**
   * Syncronus falling edge detector detects when the receiver busy signal
   * changes it's state from 1 to 0, at this point the receiver puts out it's
   * data on the bus and the data should be written to the receiver buffer.
   */
  always @(posedge i_clk) begin
    rx_busy_prev <= rx_busy;
  end

  // Receive buffer write is enabled based on the data from the edge detector
  // signal and whether the buffer is full, if buffer is full the data has to
  // be discarded.
  assign rx_buff_wr = rx_busy_prev && !rx_busy && ~&rx_buff_cnt;
  // Transimtter ce is global ce AND receiver enable
  assign rx_ce = ce_x8 && i_rxen;

  // Receiver buffer fill signals
  assign rx_buf_empty = (rx_buff_cnt == 5'b01111);
  assign rx_buf_half  = (rx_buff_cnt >= 5'b11000);
  assign rx_buf_full  = (rx_buff_cnt == 5'b11111);

  // Receiver instancing
  uart_rx rx_i (
    .i_clk         (i_clk),
    .i_ce          (rx_ce),
    .i_rst         (i_rst),
    .i_rst_err     (i_rst_err),
    .i_length      (i_length),
    .i_stop2       (i_stop2),
    .i_parity      (i_parity),
    .i_odd         (i_odd),
    .i_rx          (i_rx),
    .o_data        (rx_data),
    .o_overrun_err (o_overrun_err),
    .o_parity_err  (o_parity_err),
    .o_busy        (rx_busy)
  );

  /**
   * Output assignments
   */
  assign o_data_out = rx_buff_data;

  assign o_rxbuf_empty = rx_buf_empty;
  assign o_rxbuf_half  = rx_buf_half;
  assign o_rxbuf_full  = rx_buf_full;

  assign o_txbuf_empty = tx_buf_empty;
  assign o_txbuf_half  = tx_buf_half;
  assign o_txbuf_full  = tx_buf_full;

endmodule
