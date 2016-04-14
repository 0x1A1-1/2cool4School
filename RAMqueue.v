
module RAMqueue(rdata, raddr, wdata, waddr, we, clk);

parameter LOG2 = 9; //default is 8
parameter ENTRIES = 384;

input [7: 0] wdata;
input [LOG2 -1: 0] waddr, raddr;
input clk, we;

output reg [7: 0] rdata;

// [7:0]
reg	[LOG2 -1: 0] mem[0 : ENTRIES];


//Write to Ram
always@(posedge clk) begin
	if(we) begin //write to Ram
		mem[waddr] <= wdata;
	end
end

//Read from Ram
always@(posedge clk) begin
		rdata <= mem[raddr];
end

endmodule
		
