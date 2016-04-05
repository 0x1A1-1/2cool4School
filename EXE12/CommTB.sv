module CommTB(PB, RST_n, clk, LED);

input logic PB, RST_n, clk;
output logic [7:0] LED;

logic [15:0] cmd;
logic [15:0] cmd_out;
logic snd_cmd, send_resp, cmd_cmplt, cmd_rdy, TX_RX;
logic rst_n, PB_rise;

CommMaster iCM(.clk(clk), .rst_n(rst_n), .cmd_cmplt(cmd_cmplt), 
			.TX(TX_RX), .snd_cmd(PB_rise), .cmd(cmd));
UART_wrapper iUART(.clk(clk), .rst_n(rst_n), .cmd_rdy(cmd_rdy), .RX(TX_RX), .cmd(cmd_out), 
			.send_resp(send_resp), .TX(), .resp(), .clr_cmd_rdy(), .resp_sent());
PE_detect iPE(.clk(clk), .rst_n(rst_n), .PB(PB), .PB_rise(PB_rise));
bit_counter_16 iCount(.clk(clk), .rst_n(rst_n), .EN(PB_rise), .count(cmd));
rst_synch iRst(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));

assign LED = cmd_out[7:0];
				
endmodule
