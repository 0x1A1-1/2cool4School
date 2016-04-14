module UART_rx(clk, rst_n, rdy, cmd, RX, clr_rdy);

input clk, rst_n;
input clr_rdy, RX;
output logic rdy;
output logic [7:0] cmd;

logic [3:0] bit_cnt;
logic [6:0] baud_cnt;
logic [8:0] rx_shift_reg;

reg rx_ff1, rx_ff2;

logic start, set_rx_rdy, receiving;
wire shift;

typedef enum reg {IDLE, RXING} state_t;
state_t state, next_state;

//////////// bit_cnt  ///////////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) 
		bit_cnt <= 0;
	else if(start) 
		bit_cnt <= 0;
	else if(shift) 
		bit_cnt <= bit_cnt + 1;
end

/////////////// baud_cnt /////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		baud_cnt <= 7'h4a; //halfway to rollover for div of 108
	else if(start) 
		baud_cnt <= 7'h4a; //load at half a bit time for sampling in middle of bits
	else if(shift)
		baud_cnt <= 7'h13; //reset when baud count is full value for 921600 baud with 100MHz clk	
	else if (receiving) 
		baud_cnt <= baud_cnt + 1;
end

//////////// rx_shift_reg ////////////////
always_ff @(posedge clk) begin
	if(shift)
		rx_shift_reg <= {RX, rx_shift_reg[8:1]};
end

////////////// rdy ////////////////////
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		rdy <= 0;
	else if(start || clr_rdy)
		rdy <= 0;
	else if(set_rx_rdy)
		rdy <= 1;
end

////////// double flop RX //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		rx_ff1 <= 1;
		rx_ff2 <= 1;
	end
	else begin
		rx_ff1 <= RX;
		rx_ff2 <= rx_ff1;
	end
end
 
assign shift = &baud_cnt;
assign cmd = rx_shift_reg[7:0];

///////// state machine logic /////////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) state <= IDLE;
	else state <= next_state;
end

always_comb begin
	//default outputs
	start = 0;
	set_rx_rdy = 0;
	receiving = 0;
	next_state = IDLE;

	case(state)
		IDLE:
			if(!rx_ff2) begin
				start = 1;
				next_state = RXING;
			end
			else
				next_state = IDLE;
		
		default: begin
			if(bit_cnt == 10) begin
				set_rx_rdy = 1;
				next_state = IDLE;
			end
			else
				next_state = RXING;
			receiving = 1;
		end
	endcase
end

endmodule
