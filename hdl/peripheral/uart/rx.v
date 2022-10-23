/****************************************************************************
 * Copyright 2022 Lukasz Forenc
 *
 * File: rx.v
 *
 * This file contains the UART receiver based on the 6-state FSM and 9-bit
 * shift register.
 *
 * i_clk    - Clock input
 * i_ce     - Clock enable
 * i_rst    - Reset input
 *
 * i_length - Receive data length (i_length + 6 is the actual length)
 * i_stop2  - Two stop bits enable
 * i_parity - Parity bit enable
 * i_odd    - Odd parity enable
 * i_rx     - RX input
 *
 ***************************************************************************/

module uart_rx(
  input        i_clk,
  input        i_ce,
  input        i_rst,

  input  [1:0] i_length,
  input        i_stop2,
  input        i_parity,
  input        i_odd,
  input        i_rx,
  input        i_rst_err,

  output [8:0] o_data,
  output       o_overrun_err,
  output       o_parity_err
);

  localparam [2:0]
    S_IDLE     = 0,
    S_START_T0 = 1,
    S_START_T1 = 2,
    S_START_T2 = 3,
    S_SHIFT    = 4,
    S_PARITY   = 5,
    S_STOP_2   = 6,
    S_STOP     = 7;

  reg  [2:0] ce_cnt;
  reg        ce_div_en;
  wire       ce_cur;

  reg  [2:0] state;
  reg  [2:0] state_next;

  reg  [8:0] data_shreg;
  reg  [3:0] data_cnt;
  reg        data_load_cnt;
  wire [3:0] initial_cnt;

  reg [8:0] data_out;
  reg       overrun;
  reg       parity;

  always @(posedge i_clk) begin
    if (i_rst) begin
      state <= S_IDLE;
    end else if (ce_cur) begin
      state <= state_next;
    end
  end

  always @* begin
    case (state)

      S_IDLE:
        begin
          if (!i_rx) begin
            state_next = S_START_T0;
          end else begin
            state_next = S_IDLE;
          end
          ce_div_en = 0;
          data_load_cnt = 0;
        end

      S_START_T0:
        begin
          state_next = S_START_T1;
          ce_div_en = 0;
          data_load_cnt = 0;
        end

      S_START_T1:
        begin
          state_next = S_START_T2;
          ce_div_en = 0;
          data_load_cnt = 0;
        end

      S_START_T2:
        begin
          state_next = S_SHIFT;
          ce_div_en = 1;
          data_load_cnt = 1;
        end

      S_SHIFT:
        begin
          if (~|data_cnt) begin
            if (i_parity) begin
              state_next = S_PARITY;
            end else if (i_stop2) begin
              state_next = S_STOP_2;
            end else begin
              state_next = S_STOP;
            end
          end else begin
            state_next = S_SHIFT;
          end
          ce_div_en = 1;
          data_load_cnt = 0;
        end

      S_PARITY:
        begin
          if (i_stop2) begin
            state_next = S_STOP_2;
          end else begin
            state_next = S_STOP;
          end
          ce_div_en = 1;
          data_load_cnt = 0;
        end

      S_STOP_2:
        begin
          state_next = S_STOP;
          ce_div_en = 1;
          data_load_cnt = 0;
        end

      S_STOP:
        begin
          state_next = S_IDLE;
          ce_div_en = 1;
          data_load_cnt = 0;
        end
    endcase
  end

  always @(posedge i_clk) begin
    if (i_rst || !ce_div_en) begin
      ce_cnt <= 0;
    end else begin
      ce_cnt <= ce_cnt + 1;
    end
  end

  assign ce_cur = ~|ce_cnt && i_ce;

  always @(posedge i_clk) begin
    if (i_rst) begin
      data_shreg <= 0;
      data_cnt <= 0;
    end else if (ce_cur) begin
      if (data_load_cnt) begin
        data_shreg <= 0;
        data_cnt <= initial_cnt;
      end else if (|data_cnt) begin
        data_shreg <= { i_rx, data_shreg[8:1] };
        data_cnt <= data_cnt - 1;
      end
    end
  end

  assign initial_cnt = 6 + { 2'b00, i_length };

  always @* begin
    case (i_length)
      2'b00: data_out = { 3'b000, data_shreg[8:3] };
      2'b01: data_out = {  2'b00, data_shreg[8:2] };
      2'b10: data_out = {   1'b0, data_shreg[8:1] };
      2'b11: data_out = {         data_shreg[8:0] };
    endcase
  end

  always @(posedge i_clk) begin
    if (i_rst || i_rst_err) begin
      overrun <= 0;
    end
    else if (!i_rx && ce_cur && (state == S_STOP_2 || state == S_STOP)) begin
      overrun <= 1;
    end
  end

  assign o_data = data_out;
  assign o_overrun_err = overrun;

endmodule
