module cmd_cfg(clk, rst_n, cmd, cmd_rdy, resp_sent, rd_done, set_capture_done, rdataCH1, rdataCH2, rdataCH3, rdataCH4, rdataCH5, 
								resp, send_resp, clr_cmd_rdy, strt_rd, trig_pos, decimator, maskL, maskH, matchL, matchH, baud_cntL, baud_cntH, TrigCfg, CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg, VIL, VIH);

parameter ENTRIES = 384, LOG2_ENTRIES = 9;

input clk, rst_n;
input [15:0] cmd;
input cmd_rdy;
input resp_sent;
input rd_done;
input set_capture_done;
input [7:0] rdataCH1, rdataCH2, rdataCH3, rdataCH4, rdataCH5;

output [7:0] resp;
output send_resp;
output clr_cmd_rdy;
output strt_rd;
output [LOG2_ENTRIES-1:0] trig_pos; logic [7:0] trig_posH, trig_posL;
output reg [3:0] decimator;
output reg [7:0] maskL, maskH;
output reg [7:0] matchL, matchH;
output reg [7:0] baud_cntL, baud_cntH;
output reg [5:0] TrigCfg;
output reg [4:0] CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg;
output reg [7:0] VIL, VIH;


//////////////////////////////////////////////////
/////           REGISTER BEHAVIORS           /////
//////////////////////////////////////////////////

//////////// Channel Trig Configuration //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) TrigCfg <= 6'h03;
end

//////////// Channel Trig Configuration //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		CH1TrigCfg <= 5'h01; CH2TrigCfg <= 5'h01; CH3TrigCfg <= 5'h01; CH4TrigCfg <= 5'h01; CH5TrigCfg <= 5'h01;
	end
end

//////////// Decimator //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) decimator <= 4'h0;
end

//////////// VIH/VIL //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		VIH <= 8'hAA; VIL <= 8'h55;
	end
end

//////////// Match //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		matchH <= 8'h00; matchL <= 8'h00;
	end
end

//////////// Mask //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		maskH <= 8'h00; maskL <= 8'h00;
	end
end

//////////// Baud Count //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		baud_cntH <= 8'h06; baud_cntL <= 8'hC8;
	end
end

//////////// Trig Pos //////////
assign trig_pos = {trig_posH, trig_posL};

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		trig_posH <= 8'h00; trig_posL <= 8'h01;
	end
end
endmodule 