module SPI_RX(SS_n, SCLK, MOSI, edg, len8_16, mask, match, SPItrig, clk, rst_n);

input clk, rst_n;
input SS_n, SCLK, MOSI;
input edg, len8_16;
input [15:0] mask, match;

logic [15:0] shift_reg; //the actual shift register that data will be shifted into (MSB first)
logic shift, clr_shift_reg; //signal to shift in the MOSI LINE to the LSB of shift_reg

output logic SPItrig;


///////////SCLK flopping and shift logic//////////
logic SCLK_ff1, SCLK_ff2, SCLK_ff3; //output of flop to compare to old value

always_ff @(posedge clk) begin
	SCLK_ff1 <= SCLK;
	SCLK_ff2 <= SCLK_ff1;
	SCLK_ff3 <= SCLK_ff2;
end

assign shift = edg ? SCLK_ff2 & ~SCLK_ff3 : ~SCLK_ff2 & SCLK_ff3;


////////////MOSI flopping/////////////////
logic MOSI_ff1, MOSI_ff2, MOSI_ff3;

always_ff @(posedge clk) begin
	MOSI_ff1 <= MOSI;
	MOSI_ff2 <= MOSI_ff1;
	MOSI_ff3 <= MOSI_ff2;
end


////////////SS_n flopping/////////////////
logic SS_n_ff1, SS_n_ff2, SS_n_ff3;

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		SS_n_ff1 <= 1;
		SS_n_ff2 <= 1;
		SS_n_ff3 <= 1;
	end
	else begin
		SS_n_ff1 <= SS_n;
		SS_n_ff2 <= SS_n_ff1;
		SS_n_ff3 <= SS_n_ff2;
	end
end

//////////shift register logic///////////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) shift_reg <= 0;
	else if(clr_shift_reg) shift_reg <= 0;

	//need MOSI_ff3 to be on same clk as the triple flopped SCLK signal
	else if(shift) shift_reg <= {shift_reg[14:0], MOSI_ff3}; 
end

////////////state machine logic////////////////
typedef enum reg [1:0] {IDLE, SHIFT, DONE} state_t;
state_t state, next_state;
logic set_SPItrig;

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin 
		SPItrig <= 0;
	end
	else begin
		SPItrig <= set_SPItrig;
	end
end

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) state <= IDLE;
	else state <= next_state;
end

always_comb begin
	//default outputs
	set_SPItrig = 0;
	clr_shift_reg = 0;
	next_state = IDLE;

	case(state)
		IDLE:
			if(~SS_n_ff3) begin next_state = SHIFT; clr_shift_reg = 1; end
		SHIFT:
			if(~SS_n_ff3) next_state = SHIFT;
			else next_state = DONE;
		default:
			if(~len8_16 && &(match ~^ shift_reg) | mask) set_SPItrig = 1; 
			else if(len8_16 && &(match[7:0] ~^ shift_reg[7:0] | mask[7:0])) set_SPItrig = 1;
	endcase
end
endmodule
