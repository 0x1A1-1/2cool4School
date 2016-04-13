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

localparam RD = 2'b00;
localparam WR = 2'b01;
localparam DUMP = 2'b10;
localparam RESPOND = 2'b11;

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
/////           LOGIC                        /////
//////////////////////////////////////////////////
logic [1:0] command;
logic [5:0] addr;
logic [2:0] channel;
logic [7:0] data;
logic wr_reg;

//////////////////////////////////////////////////
/////           REGISTER BEHAVIORS           /////
//////////////////////////////////////////////////

//////////// Disect Command //////////////////////
//I dont think this is how this will work
//right now i just check the command that comes in but the state machine should react to this
//it can have some idle state and check for changes in cmd and assert a 
//write signal as necessary and send the response 

//I think this assign statment is fine, I added a cmd_rdy check in the state mahine that makes
//sure the cmd is not garbage

//I lied i think we only want to update the command if we ideling
assign command = (state == IDLE) ? cmd[15:14] : command;
assign addr    = (state == IDLE) ? cmd[13: 8] : addr;
assign channel = (state == IDLE) ? cmd[10: 8] : channel;
assign data    = (state == IDLE) ? cmd[ 7: 0] : data;

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

/////////// Set Response //////////////////
//We should somehow set the response to what ever whas in the reg 
//the user specified to read
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) resp	<= 8'h00;
	else if(state == WRITE) resp <= 8'hA5; //ack the written reg
	else if(state == READ) resp <= 8'h??; //change to read in data where ever that is
	else if(state == DUMP) //change response to the reading channel
			if(channel == 3'b001) resp <= rdataCH1; 
			else if(channel == 3'b010) resp <= rdataCH2;
			else if(channel == 3'b011) resp <= rdataCH3;
			else if(channel == 3'b100) resp <= rdataCH4;
			else if(channel == 3'b101) resp <= rdataCH5;
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
	strt_rd = 0;
	send_resp = 0;
	clr_cmd_rdy = 0;
	
	next_state = IDLE;

	//it should only change when cmd_rdy is asserted
	case(state)	
		IDLE:
			if(command == WR && cmd_rdy) begin
				wr_reg = 1;
				next_state = WRITE;
			end
			else if(command == RD && cmd_rdy) begin
				strt_rd = 1;
				next_state = READ;
			end
			else if(command == DUMP && cmd_rdy) begin
				
				next_state = DUMP;
			end
		WRITE: begin 
			wr_reg = 1; //do we need to keep wr_reg high?
			send_resp = 1;
			next_state = RESPOND;
			
			end
		READ: begin //Where do we read in the data from the registers?
			if(!rd_done)
				next_state = READ;
			else begin
				send_resp = 1; //should only be high once I think
				next_state = RESPOND;
			end
		DUMP:
			if(!rd_done)
				next_state = READ; //where do we read from?
			else begin
				send_resp = 1; //should only be high once I think
				next_state = RESPOND;
			end
		RESPOND
			if(!resp_sent) //wait in write to see if response was sent
				next_state = RESPOND;
			else begin
				next_state = IDLE;
				clr_cmd_rdy = 1;
			end

		default:

	endcase
end

endmodule 
