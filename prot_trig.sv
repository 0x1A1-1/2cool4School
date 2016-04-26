module prot_trig(clk, rst_n, TrigCfg, CH1L, CH2L, CH3L, baud_cntH, baud_cntL, maskH, maskL, matchH, matchL, protTrig);

input clk, rst_n;
input CH1L, CH2L, CH3L;
input [7:0] baud_cntH, baud_cntL;
input [7:0] maskH, maskL;
input [7:0] matchH, matchL;
input logic [3:0] TrigCfg; //lower 4 bits of 6-bit TrigCfg reg output by the cmd_cfg block

logic SPItrig, UARTtrig;

SPI_RX spi(.SS_n(CH1L), .SCLK(CH2L), .MOSI(CH3L), .edg(TrigCfg[3]), .len8_16(TrigCfg[2]), .mask({maskH, maskL}), .match({matchH, matchL}), .SPItrig(SPItrig), .clk(clk), .rst_n(rst_n));
UART_RX_trig uart_rx_trig(.clk(clk), .rst_n(rst_n), .baud_cnt({baud_cntH, baud_cntL}), .match(matchL), .RX(CH1L), .mask(maskL), .UARTtrig(UARTtrig));

output logic protTrig;

assign protTrig = (SPItrig | TrigCfg[1]) & (UARTtrig | TrigCfg[0]);

endmodule
