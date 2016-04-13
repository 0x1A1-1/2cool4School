module capture_cntrl(clk, rst_n, wrt_smpl, we, waddr);

	input clk, rst_n;
	input wrt_smpl;
	
	output reg [8:0] waddr;
	output we;
	
	assign we = wrt_smpl;
	
	always_ff @ (posedge clk, negedge rst_n)
		if(!rst_n)
			waddr <= 0;
		else if(wrt_smpl) begin
			if (waddr < 383)
				waddr <= waddr +1;
			else
				waddr <= 0;
		end
	
endmodule		
	
	