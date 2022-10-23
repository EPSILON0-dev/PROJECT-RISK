/****************************************************************************
 * Copyright 2022 Lukasz Forenc
 *
 * File: rx.v
 *
 * This file contains the UART receiver based on the 6-state FSM, 9-bit
 * shift register and 3-bit clock divider.
 *
 * i_clk         - Clock input
 * i_ce          - Clock enable
 * i_rst         - Reset input
 * i_rst_err     - Error clear input
 *
 * i_length      - Receive data length (i_length + 6 is the actual length)
 * i_stop2       - Two stop bits enable
 * i_parity      - Parity bit enable
 * i_odd         - Odd parity enable
 * i_rx          - RX input
 *
 * o_data        - Data output
 * o_overrun_err - Overrun error (state of '0' in stop bits)
 * o_parity_err  - Parity error (sum of all ones not correct)
 ***************************************************************************/

module uart_rx(
  input        i_clk,
  input        i_ce,
  input        i_rst,
  input        i_rst_err,

  input  [1:0] i_length,
  input        i_stop2,
  input        i_parity,
  input        i_odd,
  input        i_rx,

  output [8:0] o_data,
  output       o_overrun_err,
  output       o_parity_err,
  output       o_busy
);

  // FSM States
  localparam [2:0]
    S_IDLE     = 0,
    S_START_T0 = 1,
    S_START_T1 = 2,
    S_START_T2 = 3,
    S_SHIFT    = 4,
    S_PARITY   = 5,
    S_STOP_2   = 6,
    S_STOP     = 7;

  // Clock divider registers
  reg  [2:0] ce_cnt;
  reg        ce_div_en;
  wire       ce_cur;

  // FSM registers
  reg  [2:0] state;
  reg  [2:0] state_next;

  // Shift register and counters
  reg  [8:0] data_shreg;
  reg  [3:0] data_cnt;
  reg        data_load_cnt;
  wire [3:0] initial_cnt;

  // Output and error registers
  reg [8:0] data_out;
  reg       overrun;
  reg       parity;

  /**
   * FSM loads the next state when the clock is enabled
   */
  always @(posedge i_clk) begin
    if (i_rst) begin
      state <= S_IDLE;
    end else if (ce_cur) begin
      state <= state_next;
    end
  end

  // FSM next state combinational state
  always @* begin
    case (state)

      // Until there's no zero state on the RX line the FSM remains in this
      // state. When zero comes the syncronization begins (S_START_T0-T2).
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

      // The first state of the synchronization sequence, calling it "sequence"
      // might be a bit too much, it's just three delay statements before the
      // clock divider engages which hopefully syncs to the signal.
      S_START_T0:
        begin
          state_next = S_START_T1;
          ce_div_en = 0;
          data_load_cnt = 0;
        end

      // Second state of the synchronization
      S_START_T1:
        begin
          state_next = S_START_T2;
          ce_div_en = 0;
          data_load_cnt = 0;
        end

      // Third and last state of the synchronization, in this state the clock
      // divider engages.
      S_START_T2:
        begin
          state_next = S_SHIFT;
          ce_div_en = 1;
          data_load_cnt = 1;
        end

      // FSM remains in this state until all bits are shifted into the shift
      // register, then (based on the configuration signals) jumps to the
      // S_PARITY, S_STOP_2 and S_STOP state.
      S_SHIFT:
        begin
          if (data_cnt == 1) begin
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

      // In this state the parity bit is checked and based on the configuration
      // signals it jumps either to S_STOP_2 or S_STOP state.
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

      // This state is a one-cycle delay for when two stop bits are enabled,
      // it checks for overrun and goes to the actual sto bit state.
      S_STOP_2:
        begin
          state_next = S_STOP;
          ce_div_en = 1;
          data_load_cnt = 0;
        end

      // This is actual last state, directly after sampling for overrun FSM
      // starts listening for the next transmission, it might not be the best
      // solution but at least the next byte won't be overrun (hopefully).
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

  /**
   * Shift register, preloaded with zeros and with the initial_cnt the register
   * shifts in bits until value in data_cnt becomes zero.
   */
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

  /**
   * In contrast to the TX here the initial_cnt makes sense, value of zero is
   * zero and nothing happens when it's reached
   */
  assign initial_cnt = 6 + { 2'b00, i_length };

  /**
   * Simple combinational case acts as a multiplexer to get the correct shift
   * register bits on the data output, since bits are shifted LSB first there's
   * no way to get the correct output without it.
   */
  always @* begin
    case (i_length)
      2'b00: data_out = { 3'b000, data_shreg[8:3] };
      2'b01: data_out = {  2'b00, data_shreg[8:2] };
      2'b10: data_out = {   1'b0, data_shreg[8:1] };
      2'b11: data_out = {         data_shreg[8:0] };
    endcase
  end

  /**
   * Overrun register get's cleared either on the system reset or on the error
   * clear/reset. It get's set whem there's a 0 in the stop bit field.
   */
  always @(posedge i_clk) begin
    if (i_rst || i_rst_err) begin
      overrun <= 0;
    end
    else if (!i_rx && ce_cur && (state == S_STOP_2 || state == S_STOP)) begin
      overrun <= 1;
    end
  end

  /**
   * Parity register works like the overrun register, cleared on reset and set
   * if the transmission parity doesn't math the configured parity.
   */
  always @(posedge i_clk) begin
    if (i_rst || i_rst_err) begin
      parity <= 0;
    end
    else if (ce_cur && (state == S_PARITY) && ^data_shreg ^ i_rx ^ i_odd) begin
      parity <= 1;
    end
  end

  // Output assignments
  assign o_data = data_out;
  assign o_overrun_err = overrun;
  assign o_parity_err = parity;
  assign o_busy = (state != S_IDLE);

endmodule
