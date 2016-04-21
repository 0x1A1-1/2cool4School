module UART(clk, rst_n, TX, trmt, tx_data, tx_done, RX, rdy, rx_data, clr_rdy);

input clk, rst_n;
input trmt, clr_rdy;

input [7:0] tx_data;
output TX;

output [7:0] rx_data;
input RX;

output tx_done, rdy;

UART_rx RXmodule(.clk(clk), .rst_n(rst_n), .rdy(rdy), .cmd(rx_data), .RX(RX), .clr_rdy(clr_rdy));
UART_tx TXmodule(.clk(clk), .rst_n(rst_n), .trmt(trmt), .tx_data(tx_data), .TX(TX), .tx_done(tx_done));

endmodule
