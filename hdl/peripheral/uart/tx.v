/****************************************************************************
 * Copyright 2022 Lukasz Forenc
 *
 * File: tx.v
 *
 * This file contains the UART transmitter based on the 6-state FSM and 9-bit
 * shift register.
 *
 * i_clk    - Clock input
 * i_ce     - Clock enable
 * i_rst    - Reset input
 *
 * i_data   - Transmit data input
 * i_length - Transmit data length (i_length + 6 is the actual length)
 * i_stop2  - Two stop bits enable
 * i_parity - Parity bit enable
 * i_odd    - Odd parity enable
 * i_start  - Transmission start signal
 *
 * o_tx     - TX output
 * o_busy   - Busy output (set at the i_start signal and cleared when the
 *            last stop bit is reached)
 ***************************************************************************/

module uart_tx(
  input       i_clk,
  input       i_ce,
  input       i_rst,

  input [8:0] i_data,
  input [1:0] i_length,
  input       i_stop2,
  input       i_parity,
  input       i_odd,
  input       i_start,

  output      o_tx,
  output      o_busy
);

  // FSM States
  localparam [2:0]
    S_IDLE   = 0,
    S_START  = 1,
    S_SHIFT  = 2,
    S_PARITY = 3,
    S_STOP_2 = 4,
    S_STOP   = 5;

  // FSM registers
  reg  [2:0] state;
  reg  [2:0] state_next;

  // Shift register and counter
  reg  [8:0] data_shreg;
  reg  [3:0] data_cnt;
  wire [3:0] initial_cnt;
  wire [8:0] initial_data;
  reg        load_shreg;

  // Parity generator
  wire       parity_gen;

  /**
   * FSM load sthe next state when the clock is enabled
   */
  always @(posedge i_clk) begin
    if (i_rst) begin
      state <= 0;
    end else if (i_ce) begin
      state <= state_next;
    end
  end

  // FSM next state combinational state
  always @* begin
    case (state)

      // Until the start signal is sent the FSM remains in this state, when
      // the start signal comes the shift register preload begins.
      S_IDLE:
        begin
          if (i_start) begin
            state_next = S_START;
            load_shreg = 1;
          end else begin
            state_next = S_IDLE;
            load_shreg = 0;
          end
        end

      // In this state TX goes low and the shift register preload ends.
      S_START:
        begin
          load_shreg = 0;
          state_next = S_SHIFT;
        end

      // FSM remains in this state until all bits are shifted out of the shift
      // register, then (based on the configuration signals) jumps to the
      // S_PARITY, S_STOP_2 and S_STOP state.
      S_SHIFT:
        begin
          load_shreg = 0;
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
        end

      // In this state the parity bit is put on the TX output and based on the
      // configuration signals it jumps either to S_STOP_2 or S_STOP state.
      S_PARITY:
        begin
          load_shreg = 0;
          if (i_stop2) begin
            state_next = S_STOP_2;
          end else begin
            state_next = S_STOP;
          end
        end

      // This state is a one-cycle delay for when two stop bits are enabled,
      // it does nothing and goes to the actual sto bit state.
      S_STOP_2:
        begin
          load_shreg = 0;
          state_next = S_STOP;
        end

      // Stop bit at this point busy signal goes low so the next transmission
      // request can be sent, based on the start signal it either jumps to
      // S_START or S_IDLE.
      S_STOP:
        begin
          if (i_start) begin
            state_next = S_START;
            load_shreg = 1;
          end else begin
            load_shreg = 0;
            state_next = S_IDLE;
          end
        end

      // In case some alpha particle causes changes the state to unknown just
      // jump to the idle state.
      default:
        begin
          load_shreg = 0;
          state_next = S_IDLE;
        end
    endcase
  end

  /**
   * Shift register, preloaded with initial_data and with the initial_cnt
   * the register shifts out bits until value in data_cnt becomes zero, LSB
   * of the data_shreg is the output of the shift register and is connected
   * to the TX output when shift out time comes.
   */
  always @(posedge i_clk) begin
    if (i_rst) begin
      data_shreg <= 0;
      data_cnt <= 0;
    end else if (i_ce) begin
      if (load_shreg) begin
        data_shreg <= initial_data;
        data_cnt <= initial_cnt;
      end else if (|data_cnt && (state == S_SHIFT)) begin
        data_shreg <= { 1'b1, data_shreg[8:1] };
        data_cnt <= data_cnt - 1;
      end
    end
  end

  /**
   * Initial preload data, no preload processing is required for i_data as the
   * unused bits are just ingored and never go out of the shift registers.
   * The counter value is the number of bits - 1 as the value of zero is treated
   * as the last bit (MSB) and only after it FSM goes into STOP states.
   */
  assign initial_cnt = 4'd5 + { 2'd0, i_length };
  assign initial_data = i_data;

  /**
   * Parity is generated based on all bits as they are filtered somewhere else
   */
  assign parity_gen = ^initial_data ^ i_odd;

  // In every state besides S_START, S_SHIFT and S_PARITY the TX output is one
  assign o_tx = (state != S_START) && (state != S_SHIFT) && (state != S_PARITY) ||
  // In shift (data) phase the shift register takes over the TX line
    (state == S_SHIFT) && data_shreg[0] ||
  // In parity phase the tx line is the parity generator bit
    (state == S_PARITY) && parity_gen;

  // All states besides S_IDLE and S_STOP are considered being busy
  assign o_busy = (state != S_IDLE) && (state != S_STOP);

endmodule
