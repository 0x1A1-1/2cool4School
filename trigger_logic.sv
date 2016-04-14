module trigger_logic(CH1Trig, CH2Trig, CH3Trig, CH4Trig, CH5Trig, protTrig, armed, set_capture_done, clk, rst_n, triggered);

input CH1Trig, CH2Trig, CH3Trig, CH4Trig, CH5Trig, protTrig; 
input armed, set_capture_done;
input clk, rst_n;

reg d;

output reg triggered;

always_comb
	d = ~(set_capture_done | ~(triggered | (armed & (CH1Trig & CH2Trig & CH3Trig & CH4Trig & CH5Trig & protTrig))));

always @(posedge clk, negedge rst_n) 
	if(!rst_n) triggered <= 0;
	else triggered <= d;

endmodule
