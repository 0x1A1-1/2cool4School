module bit_counter_16 (clk, rst_n, EN, count);

input logic clk, rst_n, EN;
output logic [15:0] count;

always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		count <= 16'h0000;
	else if(EN)
		count <= count + 1;

endmodule