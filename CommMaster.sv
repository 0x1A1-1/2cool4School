module CommMaster(clk, rst_n, cmd, snd_cmd, TX, cmd_cmplt, RX, rdy, rx_data, clr_rdy);

input clk, rst_n;
input snd_cmd;
input [15:0] cmd;

input RX, clr_rdy;
output logic [7:0] rx_data;
output logic rdy;

logic [7:0] low_byte;
logic [7:0] tx_data;
logic trmt, sel, tx_done;

output logic TX, cmd_cmplt;

UART(	.clk(clk), .rst_n(rst_n), 
		.TX(TX), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done), 
		.RX(RX), .rdy(rdy), .rx_data(rx_data), .clr_rdy(clr_rdy));

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) low_byte <= 0;
	else if(snd_cmd) low_byte <= cmd[7:0];
end

/////////////tx_data mux///////////////
assign tx_data = sel ? cmd[15:8] : low_byte;

typedef enum reg [1:0] {IDLE, HIGH, LOW} state_t;
state_t state, next_state;

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) state <= IDLE;
	else state <= next_state;
end

always_comb begin
	sel = 0;
	trmt = 0;
	cmd_cmplt = 0;
	next_state = IDLE;

	case(state)
		IDLE:
			if(snd_cmd) begin
				trmt = 1;
				sel = 1;
				next_state = HIGH;
			end
		HIGH:
			if(tx_done) begin
				trmt = 1;
				next_state = LOW;
			end
			else begin
				sel = 1;
				next_state = HIGH;
			end
		LOW:
			if(tx_done) begin
				cmd_cmplt = 1;
				next_state = IDLE;
			end
			else begin
				next_state = LOW;
			end
	endcase
end

endmodule
