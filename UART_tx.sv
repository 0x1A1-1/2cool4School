module UART_TX(clk, rst_n, trmt, tx_data, TX, tx_done);

input clk, rst_n;
input trmt;
input [7:0] tx_data;
output logic TX, tx_done;

logic [3:0] bit_cnt;
logic [6:0] baud_cnt;
logic [9:0] tx_shift_reg;

//typedef enum reg [1:0] {IDLE, HOLD, SHIFT} state_t;
typedef enum reg {IDLE, TXING} state_t;
state_t state, next_state;

logic load, shift, transmitting, set_done, clr_done;

//////////// bit_cnt  ///////////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		bit_cnt <= 0;
	else if(load) 
		bit_cnt <= 0;
	else if(shift) 
		bit_cnt <= bit_cnt + 1;
end

/////////////// baud_cnt /////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		baud_cnt <= 0;
	else if(load | shift) 
		baud_cnt <= 0;
	else if(transmitting) 
		baud_cnt <= baud_cnt + 1;
end

///////////// tx_shift_reg ////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) 
		tx_shift_reg <= 10'h3ff;
	else if(load) 
		tx_shift_reg <= {1'b1, tx_data, 1'b0};
	else if(shift) 
		tx_shift_reg <= {1'b1, tx_shift_reg[9:1]}; 
end

assign shift = (baud_cnt == 108) ? 1 : 0;

assign TX = tx_shift_reg[0];

///////// state machine logic //////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) 
		state <= IDLE;
	else 
		state <= next_state;
end

always_comb begin
	//default outputs
	load = 0;
	transmitting = 0;
	set_done = 0;
	clr_done = 0;
	next_state = IDLE;
	
	case(state)
		IDLE:
			if(!trmt) begin
				set_done = 1;
				next_state = IDLE;
			end
			else begin
				load = 1;
				transmitting = 1;
				clr_done = 1;
				next_state = TXING;
			end

		default: begin
			if(bit_cnt == 10) begin
				transmitting = 0;
				set_done = 1;
				next_state = IDLE;
			end
			else begin
				transmitting = 1;
				next_state = TXING;
			end
		end

	endcase
end

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) tx_done <= 0;
	else tx_done <= set_done & ~clr_done; 
end

endmodule
