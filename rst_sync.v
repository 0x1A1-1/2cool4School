module reset_synch(RST_n, clk, rst_n);

input RST_n, clk;
output reg rst_n;

reg q;

always @(negedge clk, negedge RST_n) begin
	if(!RST_n) begin
		rst_n <= 0;
		q <= 0;
	end
	else begin
		q <= 1;
		rst_n <= q;
	end
end

endmodule
