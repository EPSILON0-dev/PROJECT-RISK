`include "uart.v"

module uart_tb;

  initial begin
    $dumpfile("uart_log.vcd");
    $dumpvars(0, uart_i);
  end

  reg        clk = 0;
  reg        rst = 1;
  reg  [1:0] length = 2;
  reg        stop2 = 0;
  reg        parity = 0;
  reg        odd = 0;

  reg  [8:0] data = 0;
  reg        wr = 0;
  reg        rd = 0;

  always #1 clk = !clk;

  initial begin
    #10 rst = 0;

    #10
    data = 9'h048;
    wr = 1'b1;
    #2
    data = 9'h055;
    wr = 1'b1;
    #2
    data = 9'h04A;
    wr = 1'b1;
    #2
    data = 9'h045;
    wr = 1'b1;
    #2
    data = 9'h043;
    wr = 1'b1;
    #2
    data = 9'h031;
    wr = 1'b1;
    #2
    data = 9'h032;
    wr = 1'b1;
    #2
    data = 9'h033;
    wr = 1'b1;
    #2
    data = 9'h034;
    wr = 1'b1;
    #2
    data = 9'h035;
    wr = 1'b1;
    #2
    data = 9'h036;
    wr = 1'b1;
    #2
    data = 9'h037;
    wr = 1'b1;
    #2
    data = 9'h038;
    wr = 1'b1;
    #2
    data = 9'h039;
    wr = 1'b1;
    #2
    data = 9'h155;
    wr = 1'b1;
    #2
    data = 9'h1FF;
    wr = 1'b1;
    #2
    data = 9'h000;
    wr = 1'b0;

    #8000
    rd = 1'b1;
    #36
    rd = 1'b0;

    #100 $finish;
  end

  wire loopback;

  // verilator lint_off PINCONNECTEMPTY
  uart uart_i (
    .i_clk(clk),
    .i_rst(rst),
    .i_clk_div(16'd1),

    .i_txen(1'b1),
    .i_rxen(1'b1),

    .i_length(length),
    .i_stop2(stop2),
    .i_parity(parity),
    .i_odd(odd),

    .i_rst_err(1'b0),
    .i_clear_txbuf(1'b0),
    .i_clear_rxbuf(1'b0),

    .i_data_in(data),
    .o_data_out(),
    .i_txwr(wr),
    .i_rxrd(rd),

    .o_overrun_err(),
    .o_parity_err(),

    .o_txbuf_empty(),
    .o_txbuf_half(),
    .o_txbuf_full(),
    .o_rxbuf_empty(),
    .o_rxbuf_half(),
    .o_rxbuf_full(),

    .o_tx(loopback),
    .i_rx(loopback)
  );

endmodule
