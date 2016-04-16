module UART_wrapper(clk, rst_n , resp, send_resp, clr_cmd_rdy, RX, TX, resp_sent, cmd_rdy, cmd);

input clk, rst_n;
input [7:0] resp; 
input send_resp, clr_cmd_rdy;
input RX;

logic byte_rdy;					//high when UART is done rxing a byte
logic clr_rdy; 					//set by state machine when we are done with this byte
logic byte_sel;					//set by state machine depending on which byte we need to recirculate
logic set_cmd_rdy;			//set by state machine when we are done receiving two bytes
logic [7:0] high_byte;	//the flop we are using to store the byte. High byte of cmd
logic [7:0] low_byte;		//net connected to rx_data from the 8-bit UART. Low btye of cmd

output TX;
output resp_sent;
output reg cmd_rdy;
output [15:0] cmd;

UART UART_8bit(.clk(clk), .rst_n(rst_n), .TX(TX), .trmt(send_resp), .tx_data(resp), 
	.tx_done(resp_sent), .RX(RX), .rdy(byte_rdy), .rx_data(low_byte), .clr_rdy(clr_rdy));


///////////////high byte select////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) 
		high_byte <= 0;
	else if(byte_sel) 
		high_byte <= low_byte;
end


////////////// cmd_rdy ////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cmd_rdy <= 0;
	else if(clr_cmd_rdy)
		cmd_rdy <= 0;
	else if(set_cmd_rdy)
		cmd_rdy <= 1;
end

assign cmd = {high_byte[7:0], low_byte[7:0]};


//////////////state machine logic/////////
typedef enum reg [1:0] {HIGH_BYTE, LOW_BYTE, DONE} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= HIGH_BYTE;
	else
		state <= next_state;
end

always_comb begin 
	//default outputs
	byte_sel = 0;
	clr_rdy = 0;
	set_cmd_rdy = 0;

	case(state)
		HIGH_BYTE:
			if(byte_rdy) begin
				byte_sel = 1;
				clr_rdy = 1;
				next_state = LOW_BYTE;
			end
			else begin
				next_state = HIGH_BYTE;
			end
		LOW_BYTE:
			if(byte_rdy) begin
				set_cmd_rdy = 1;
				next_state = DONE;
			end
		default:
			if(clr_cmd_rdy) begin
				clr_rdy = 1;
				next_state = HIGH_BYTE;
			end
			else begin
				set_cmd_rdy = 1;
				next_state = DONE;
			end
	endcase
end

endmodule
