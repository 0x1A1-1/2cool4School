module cmd_cfg_tb();

logic [15:0] cmd;
logic [15:0] cmd_out;
logic snd_cmd, send_resp, cmd_cmplt, cmd_rdy, TX_RX, clr_cmd_rdy;
logic clk, rst_n;

CommMaster iCM(.clk(clk), .rst_n(rst_n), .cmd_cmplt(cmd_cmplt), 
			.TX(TX_RX), .snd_cmd(snd_cmd), .cmd(cmd));
UART_wrapper iUART(.clk(clk), .rst_n(rst_n), .cmd_rdy(cmd_rdy), .RX(TX_RX), .cmd(cmd_out), 
			.send_resp(send_resp), .TX(), .resp(), .clr_cmd_rdy(clr_cmd_rdy), .resp_sent());
			
cmd_cfg iCMD(.clk(), .rst_n(), .cmd(), .cmd_rdy(), .resp_sent(), .rd_done(), .set_capture_done(), .rdataCH1(), .rdataCH2(), .
			rdataCH3(), .rdataCH4(), .rdataCH5(), .resp(), .send_resp(), .clr_cmd_rdy(), .strt_rd(), .trig_pos(), .
			decimator(), .maskL(), .maskH(), .matchL(), .matchH(), .baud_cntL(), .baud_cntH(), .TrigCfg(), .CH1TrigCfg(), .
			CH2TrigCfg(), .CH3TrigCfg(), .CH4TrigCfg(), .CH5TrigCfg(), .VIL(), .VIH());

RAMqueue iRAM(.clk(), .we(), .waddr(), .wdata(), .raddr(), .rdata());

//we still need a RAMqueue interface...Pontentially in capture?
			
endmodule