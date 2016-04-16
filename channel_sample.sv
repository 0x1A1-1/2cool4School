module sampler_reg(clk, smpl_clk, CH_Low, CH_High, smpl, CHLff5, CHHff5);

input clk, smpl_clk;
input CH_Low, CH_High;

logic CHLff1, CHLff2, CHLff3, CHLff4;
logic CHHff1, CHHff2, CHHff3, CHHff4; 

output reg [7:0] smpl;
output reg CHLff5, CHHff5;

////////// CH_Low flops //////////
always_ff @(negedge smpl_clk) begin
	CHLff1 <= CH_Low;
	CHLff2 <= CHLff1;
	CHLff3 <= CHLff2;
	CHLff4 <= CHLff3;
	CHLff5 <= CHLff4;
end

////////// CH_High flops //////////
always_ff @(negedge smpl_clk) begin
	CHHff1 <= CH_High;
	CHHff2 <= CHHff1;
	CHHff3 <= CHHff2;
	CHHff4 <= CHHff3;
	CHHff5 <= CHHff4;
end

////////// output sample ///////////
always_ff @(posedge clk) begin
	smpl[0] <= CHLff5;
	smpl[1] <= CHHff5;
	smpl[2] <= CHLff4;
	smpl[3] <= CHHff4;
	smpl[4] <= CHLff3;
	smpl[5] <= CHHff3;
	smpl[6] <= CHLff2;
	smpl[7] <= CHHff2;
end

endmodule
