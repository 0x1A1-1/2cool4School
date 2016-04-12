module channel_trigger_logic(clk, set_armed, CHxHff5, CHxLff5, CHxTrigCfg, ChxTrig);

input clk, set_armed, CHxHff5, CHxLff5;
input [4:0] CHxTrigCfg; //we only use the 5 bits of the register

output logic ChxTrig;

logic low_level, high_level, negative_edge, positive_edge;
logic Hff1_1, Hff1_2, Lff1_1, Lff1_2, Hff2, Lff2; //ff ni between, from top to bottom

assign low_level = Lff2 & CHxTrigCfg[1];
assign high_level = Hff2 & CHxTrigCfg[2];
assign negative_edge = Lff1_2 & CHxTrigCfg[3];
assign positive_edge = Hff1_2 & CHxTrigCfg[4];
assign ChxTrig = CHxTrigCfg[0] | low_level | high_level | negative_edge | positive_edge;

//1'b1 CHxHff5 flop
always_ff @(posedge CHxHff5, set_armed) 
	if(!set_armed)
		Hff1_1 <= 1'b0;
	else 
		Hff1_1 <= 1'b1;

always_ff @ (posedge clk) 
	Hff1_2 <= Hff1_1;


//1'b1 CHxLff5 flop
always_ff @(negedge CHxLff5, set_armed)
	if(!set_armed)
		Lff1_1 <= 1'b1;
	else
		Lff1_1 <= 1'b0;

always_ff @ (posedge clk)
	Lff1_2 <= Lff1_1;


//CHxHff5 flop
always_ff @(posedge clk)
	Hff2 <= CHxHff5;

//CHxLff5 flop
always_ff @(posedge clk)
	Lff2 <= CHxLff5;

		
endmodule
