module channel_trigger_logic(clk, set_armed, CHxHff5, CHxLff5, CHxTrigCfg, ChxTrig);

input logic clk, set_armed, CHxHff5, CHxLff5;
input logic [4:0] CHxTrigCfg; //we only use the 5 bits of the register

output logic ChxTrig;

logic low_level, high_level, negative_edge, positive_edge;
logic ll_ff, hl_ff, ne_ff, pe_ff; //high level flip flop etc.
logic ne, pe; //negative edge, positive edge;


assign low_level = ll_ff & CHxTrigCfg[1];
assign high_level = hl_ff & CHxTrigCfg[2];
assign negative_edge = ne_ff & CHxTrigCfg[3];
assign positive_edge = pe_ff & CHxTrigCfg[4];
assign ChxTrig = (CHxTrigCfg[0] | low_level | high_level | negative_edge | positive_edge);

//clock flops
always_ff @(posedge clk) begin
	ll_ff <= CHxLff5;
	hl_ff <= CHxHff5;
	ne_ff <= ne;
	pe_ff <= pe;
end

//negative edge flop
always_ff @(negedge CHxLff5)
	if(!set_armed)
		ne <= 1'b1;
	else
		ne <= 1'b0;

//positive edge flop
always_ff @(posedge CHxHff5)
	if(!set_armed)
		pe <= 1'b1;
	else
		pe <= 1'b0;
		
endmodule		
