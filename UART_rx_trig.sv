module UART_RX_trig(clk, rst_n, RX, baud_cnt, match, mask, UARTtrig);

input clk, rst_n;
input RX;
input [15:0] baud_cnt;
input [7:0] match, mask;

output reg UARTtrig;

logic [3:0] bit_cnt;
logic [15:0] baud_counter;
logic [8:0] rx_shift_reg;

logic start, rdy, receiving;
wire shift;

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
		baud_counter <= 0;
	else if(start) 
		baud_counter <= baud_cnt >> 1;
	else if(shift)
		baud_counter <= 0; 
	else if(receiving) 
		baud_counter <= baud_counter + 1;
end

//////////// rx_shift_reg ////////////////
always_ff @(posedge clk) begin
	if(shift)
		rx_shift_reg <= {RX, rx_shift_reg[8:1]};
end

assign shift = (baud_counter == baud_cnt) ? 1 : 0; 

/////////// UARTtrig /////////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) UARTtrig <= 0;
	else if(rdy) UARTtrig <= (match[7:0] ^ rx_shift_reg[7:0] == (match[7:0] ^ rx_shift_reg[7:0]) & mask[7:0]) ? 1 : 0;
	else UARTtrig <= 0; 
end

///////// state machine logic /////////////
typedef enum reg {IDLE, RXING} state_t;
state_t state, next_state;

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) state <= IDLE;
	else state <= next_state;
end

always_comb begin
	//default outputs
	start = 0;
	rdy = 0;
	receiving = 0;
	next_state = IDLE;

	case(state)
		IDLE:
			if(!RX) begin
				start = 1;
				next_state = RXING;
			end
			else
				next_state = IDLE;
		
		default: begin
			if(bit_cnt == 10) begin
				rdy = 1;
				next_state = IDLE;
			end
			else
				next_state = RXING;
			receiving = 1;
		end
	endcase
end

endmodule
