module uart_tx(
  input i_clk,
  input i_ce,
  input i_rst,
  input [8:0] i_data,
  input       i_2stop,

)