`include "tx.v"

module tx_tb;

  reg       clk = 0;
  reg       ce = 1;
  reg       rst = 1;
  reg [8:0] data = 9'h069;
  reg [1:0] length = 2;
  reg       stop2 = 1;
  reg       parity = 0;
  reg       odd = 0;
  reg       start = 0;

  wire      tx;
  wire      busy;

  initial begin
    #10 rst = 0;
    #2 start = 1;
    #2 start = 0;
    #100 $finish;
  end

  initial begin
    $display("start |    data   | len | 2stop | par | odd | tx | busy | state | cnt |");
  end
  always @(posedge clk) begin
    $display("  %b   | %b |  %d  |   %b   |  %b  |  %b  |  %b |   %b  |   %d   | %d  |",
      start, data, length, stop2, parity, odd, tx, busy, tx_i.state, tx_i.data_cnt);
  end

  always #1 clk = !clk;
  // always #2 ce = !ce;

  uart_tx tx_i (
    .i_clk    (clk),
    .i_ce     (ce),
    .i_rst    (rst),
    .i_data   (data),
    .i_length (length),
    .i_stop2  (stop2),
    .i_parity (parity),
    .i_odd    (odd),
    .i_start  (start),
    .o_tx     (tx),
    .o_busy   (busy)
  );

endmodule
