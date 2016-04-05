module PE_detect(clk, rst_n, PB, PB_rise);

input clk, rst_n, PB;
output logic PB_rise;

logic ff1, ff2, ff3;

always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		ff1 <= 0;
		ff2 <= 0;
		ff3 <= 0;
	end else begin
		ff1 <= PB;
		ff2 <= ff1;
		ff3 <= ff2;
	end
end

assign PB_rise = ff2 & (~ff3);

endmodule