`include "rx.v"

module rx_tb;

  reg        clk = 0;
  reg        ce = 1;
  reg        rst = 1;
  reg  [1:0] length = 0;
  reg        stop2 = 0;
  reg        parity = 0;
  reg        odd = 0;
  reg        rx = 1;

  wire [8:0] data;
  wire       busy;
  wire       overrun_err;
  wire       parity_err;

  initial begin
    $display(" len | 2stop | par | odd | rx | busy | state | ce_sel | overrun | data");
    #10 rst = 0;
    #800;
    $display("  %d  |   %b   |  %b  |  %b  |  %b |   %b  |   %d   |    %b   |    %b    | %b",
        length, stop2, parity, odd, rx, busy, rx_i.state, rx_i.ce_div_en, overrun_err, data);
    $finish;
  end

  always #1 clk = !clk;
  // always #2 ce = !ce;

  initial begin
    #100;
    #16 rx = 0; // Start
    #16 rx = 1; // b0
    #16 rx = 0; // b1
    #16 rx = 0; // b2
    #16 rx = 0; // b3
    #16 rx = 0; // b4
    #16 rx = 0; // b5
    #16 rx = 0; // b6
    #16 rx = 1; // b7
    // #16 rx = 0; // b8
    // #16 rx = 0; // parity
    #16 rx = 1; // stop
    #16 rx = 1; // stop2
  end

  uart_rx rx_i (
    .i_clk         (clk),
    .i_ce          (ce),
    .i_rst         (rst),
    .i_length      (length),
    .i_stop2       (stop2),
    .i_parity      (parity),
    .i_odd         (odd),
    .i_rx          (rx),
    .o_data        (data),
    .o_overrun_err (overrun_err),
    .o_parity_err  (parity_err)
  );

endmodule
