module tb_tasks();

////// Stimulus is declared as type reg ///////
reg REF_CLK, RST_n;
reg [15:0] host_cmd;			// command host is sending to DUT
reg snd_cmd;					// asserted to initiate sending of command
reg clr_resp_rdy;				// asserted to knock down resp_rdy
reg [1:0] clk_div;				// counter used to derive 100MHz clk from clk400MHz
reg strt_tx;					// kick off unit used for protocol triggering
wire clk;
wire [7:0] resp;
wire resp_rdy;	


parameter TRIG_CFG = 6'b000000;
parameter CH1TRIG_CFG = 6'b000001;
parameter CH2TRIG_CFG = 6'b000010;
parameter CH3TRIG_CFG = 6'b000011;
parameter CH4TRIG_CFG = 6'b000100;
parameter CH5TRIG_CFG = 6'b000101;
parameter DECIM = 6'b000110;
parameter VIH = 6'b000111;
parameter VIL = 6'b001000;
parameter MTCH_H = 6'b001001;
parameter MTCH_L = 6'b001010;
parameter MSK_H = 6'b001011;
parameter MSK_L = 6'b001100;
parameter BAUD_CNT_H = 6'b001101;
parameter BAUD_CNT_L = 6'b001110;
parameter TRIG_POS_H = 6'b001111;
parameter TRIG_POS_L = 6'b010000;

parameter WR = 2'b01;
parameter RD = 2'b00;
parameter DUMP = 2'b10;

parameter POS_ACK = 8'hA5;
parameter NEG_ACK = 8'hEE;

//initializing the logic analyzer
task initialize;
	begin
		REF_CLK = 0;
		host_cmd = 0;
		snd_cmd = 0;
		clr_resp_rdy = 0;
		clk_div = 0; 
		strt_tx = 0;

		RST_n = 1;
		repeat (10) @(negedge clk)
		RST_n = 0;
		repeat (10) @(negedge clk)
		RST_n = 1;	
		$disaplay("initialize done");
	end
endtask// initialize

//sending cmd via UART into design
task sndcmd; 
	input  [15:0] mstr_cmd; // mstr_cmd = {CMD[1:0],ADDR[5:0],DATA[7:0]}
begin
	host_cmd = mstr_cmd;
	snd_cmd = 1;
	$display("CMD sent");
end
endtask//sndcmd

//check the response from our desgin
task chkresp;
	input [7:0] resp_req; //response require to have refer to our design
begin
	fork
		begin: timeout1
			repeat(70000) @(posedge clk);
			$display("ERROR: timeout due to lack of response");
			$stop();
		end	
		begin
			@(posedge resp_rdy);
			disable timeout1;
			clr_resp_rdy = 1; // assert clr_resp_rdy, kick down resp_rdy	
			if(resp_req ==resp) 
				$display("response received and correct");
			else
				$display("response received but incorrect");
		end					
	join
end
endtask//ckresp

task chkdump1
	begin
		host_cmd = 16'b10_000_001_00000000; //dump channel 1
		snd_cmd = 1;
		while
		
	end
endtask

endmodule
