/****************************************************************************
 * Copyright 2022 Lukasz Forenc
 *
 * File: baud_gen.v
 *
 * This file contains the baud rate generator for the UART module, it
 * generates two clock enable signals, the faster one o_ce_8x, and 8 times
 * slower o_ce, the faster one is used for the RX where we need faster clock
 * to sync up with the start bit of the incoming transmission, the slower one
 * is used for the TX as it doesn't have to sync up with anything.
 *
 * i_clk     - Clock input
 * i_rst     - Reset input
 * i_clk_div - Clock division amount
 *
 * o_ce_8x   - faster clock enable
 * o_ce      - slower clock enable
 ***************************************************************************/

module uart_baud_gen(
  input         i_clk,
  input         i_rst,
  input  [15:0] i_clk_div,
  output        o_ce_x8,
  output        o_ce
);

  reg [15:0] clk_cnt_1;
  wire       clk_cnt_1_top;
  reg [ 2:0] clk_cnt_2;
  wire       clk_cnt_2_top;

  /* First counter - main division counter, it counts up to (and including)
   * the i_clk_div value, and on top generates the clock enable for the next
   * counter.
   */
  always @(posedge i_clk) begin
    if (i_rst || clk_cnt_1_top) begin
      clk_cnt_1 <= 0;
    end else begin
      clk_cnt_1 <= clk_cnt_1 + 16'd1;
    end
  end
  assign clk_cnt_1_top = (clk_cnt_1 == i_clk_div);

  /* The second counter - modulo 8 counter used to generate clock for TX */
  always @(posedge i_clk) begin
    if (i_rst) begin
      clk_cnt_2 <= 0;
    end else begin
      if (clk_cnt_1_top) begin
        clk_cnt_2 <= clk_cnt_2 + 3'd1;
      end
    end
  end
  assign clk_cnt_2_top = (clk_cnt_2 == 3'd7);

  // Output assignments
  assign o_ce_x8 = clk_cnt_1_top;
  assign o_ce    = clk_cnt_2_top && clk_cnt_1_top;

endmodule
