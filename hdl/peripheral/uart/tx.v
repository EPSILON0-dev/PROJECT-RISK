module uart_tx(
  input       i_clk,
  input       i_ce,
  input       i_rst,

  input [8:0] i_data,
  input [1:0] i_length,
  input       i_2stop,
  input       i_parity,
  input       i_odd,
  input       i_start,

  output      o_tx,
  output      o_busy
);



endmodule
