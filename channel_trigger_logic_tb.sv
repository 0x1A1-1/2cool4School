module trigger_tb();

logic clk, set_armed, CHxHff5, CHxLff5, ChxTrig;
logic [4:0] CHxTrigCfg;

channel_trigger_logic iTrig(.clk(clk), .set_armed(set_armed), .CHxHff5(CHxHff5), 
							.CHxLff5(CHxLff5), .CHxTrigCfg(CHxTrigCfg), .ChxTrig(ChxTrig));

initial begin
clk = 1'b0;
set_armed = 1'b1;
CHxLff5 = 1'b0;
CHxHff5 = 1'b1;
CHxTrigCfg = 5'b11110;
repeat(10000) @(posedge clk);
$stop;
end

always #5 clk = ~clk;
always #10 CHxHff5 = ~CHxHff5;
always #15 CHxLff5 = ~CHxLff5;
always #15 set_armed = ~set_armed;

endmodule
