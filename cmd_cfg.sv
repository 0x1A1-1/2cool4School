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

//I dont think this is how this will work
//right now i just check the command that comes in but the state machine should react to this
//it can have some idle state and check for changes in cmd and assert a 
//write signal as necessary and send the response 
logic [1:0] command;
assign command = cmd[15:14];
logic [5:0] addr;
assign addr    = cmd[13: 8];
logic [2:0] channel;
assign channel = cmd[10: 8];
logic [7:0] data;
assign data    = cmd[ 7: 0];

localparam RD = 2'b00;
localparam WR = 2'b01;
localparam DUMP = 2'b10;

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
	else if(wr_reg && addr == 6'h00) TrigCfg <= data;
	//add another else if here?
end

//////////// Channel Trig Configuration //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		CH1TrigCfg <= 5'h01; CH2TrigCfg <= 5'h01; CH3TrigCfg <= 5'h01; CH4TrigCfg <= 5'h01; CH5TrigCfg <= 5'h01;
	end
	else if(wr_reg && addr == 6'h01) CH1TrigCfg <= data;
	else if(wr_reg && addr == 6'h02) CH2TrigCfg <= data;
	else if(wr_reg && addr == 6'h03) CH3TrigCfg <= data;
	else if(wr_reg && addr == 6'h04) CH4TrigCfg <= data;
	else if(wr_reg && addr == 6'h05) CH5TrigCfg <= data;
end

//////////// Decimator //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) decimator <= 4'h0;
	else if(wr_reg && addr == 6'h06) decimator <= data;
end

//////////// VIH/VIL //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		VIH <= 8'hAA; VIL <= 8'h55;
	end
	else if(wr_reg && addr == 6'h07) VIH <= data;
	else if(wr_reg && addr == 6'h08) VIL <= data;
end

//////////// Match //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		matchH <= 8'h00; matchL <= 8'h00;
	end
	else if(wr_reg && addr == 6'h09) matchH <= data;
	else if(wr_reg && addr == 6'h0A) matchL <= data;
end

//////////// Mask //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		maskH <= 8'h00; maskL <= 8'h00;
	end
	else if(wr_reg && addr == 6'h0B) maskH <= data;
	else if(wr_reg && addr == 6'h0C) maskL <= data;
end

//////////// Baud Count //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		baud_cntH <= 8'h06; baud_cntL <= 8'hC8;
	end
	else if(wr_reg && addr == 6'h0D) baud_cntH <= data;
	else if(wr_reg && addr == 6'h0E) baud_cntL <= data;
end

//////////// Trig Pos //////////
assign trig_pos = {trig_posH, trig_posL};

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		trig_posH <= 8'h00; trig_posL <= 8'h01;
	end
	else if(wr_reg && addr == 6'h0F) trig_posH <= data;
	else if(wr_reg && addr == 6'h10) trig_posL <= data;
end

/////////// State Machine Logic //////////
typedef enum reg [2:0] {IDLE, WRITE, READ, DUMP} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) state <= IDLE;
	else state <= next_state;
end

always_comb begin
	//default outputs
	wr_reg = 0;
	next_state = IDLE;

	case(state)	
		IDLE:
			if(command == WR) begin
				wr_reg = 1;
				next_state = WRITE;
			end
			else if(command == RD) begin
				next_state = READ;
			end
			else if(command == DUMP) begin
				next_state = DUMP;
			end
		WRITE:

		READ:

		DUMP:

		default:

	endcase
end

endmodule 