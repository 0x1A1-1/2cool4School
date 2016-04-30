
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

parameter DPCH1 = 6'b000001;
parameter DPCH2 = 6'b000010;  
parameter DPCH3 = 6'b000011; 
parameter DPCH4 = 6'b000100; 
parameter DPCH5 = 6'b000101; 


parameter WR = 2'b01;
parameter RD = 2'b00;
parameter DUMP = 2'b10;

parameter POS_ACK = 8'hA5;
parameter NEG_ACK = 8'hEE;

//initializing the logic analyzer
task initialize;
	begin
		$display("initialize start");
		REF_CLK = 0;
		host_cmd = 0;
		send_cmd = 0;
		clr_resp_rdy = 0; 
		strt_tx = 0;

		RST_n = 1;
		repeat (10) @(negedge REF_CLK);
		RST_n = 0;
		repeat (10) @(negedge REF_CLK);
		RST_n = 1;	
		repeat (10) @(negedge REF_CLK);
		RST_n = 0;
		repeat (10) @(negedge REF_CLK);
		RST_n = 1;	
		$display("initialize done");
	end
endtask// initialize

//sending cmd via UART into design
task sndcmd; 
	input  [15:0] mstr_cmd; // mstr_cmd = {CMD[1:0],ADDR[5:0],DATA[7:0]}
begin
	host_cmd = mstr_cmd;
	send_cmd = 1;
	repeat (10) @(negedge clk);
	send_cmd = 0;
	$display("Command sent");
end
endtask//sndcmd

//check the response from our desgin
task chkresp;
	input [7:0] resp_req; //response require to have refer to our design
begin
		$display("checking response");
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
			repeat (2) @(negedge clk);
			clr_resp_rdy = 0; // assert clr_resp_rdy, kick down resp_rdy
			if(resp_req ==resp) 
				$display("response received and correct");
			else
				$display("response received but incorrect");
		end					
	join
end
endtask//ckresp

//writing all the dump resp into file
task dump;
  input [6:0] CH;
begin
	$display("start dumping");
	case(CH)
	  6'b000001:begin
	    for(int j = 0; j < 384; j = j + 1) begin
		//checking dump of every address
		@(posedge resp_rdy);
		$fdisplay(fptr1, "%h", resp);
		$display("dumping into CH1 file %b", resp);
	    end	
	  end
	  6'b000010:begin
	    for(int j = 0; j < 384; j = j + 1) begin
		//checking dump of every address
		@(posedge resp_rdy);
		$fdisplay(fptr2, "%h", resp);
		$display("dumping into CH2 file %b", resp);
	    end	
	  end
	  6'b000011:begin
	    for(int j = 0; j < 384; j = j + 1) begin
		//checking dump of every address
		@(posedge resp_rdy);
		$fdisplay(fptr3, "%h", resp);
		$display("dumping into CH3 file %b", resp);
	    end	
	  end	  
	  6'b000100:begin
	    for(int j = 0; j < 384; j = j + 1) begin
		//checking dump of every address
		@(posedge resp_rdy);
		$fdisplay(fptr4, "%h", resp);
		$display("dumping into CH4 file %b", resp);
	    end	
	  end
	  6'b000101:begin
	    for(int j = 0; j < 384; j = j + 1) begin
		//checking dump of every address
		@(posedge resp_rdy);
		$fdisplay(fptr5, "%h", resp);
		$display("dumping into CH5 file %b", resp);
	    end	
	  end
	 endcase
	$display("stop dumping");
end
endtask

task PollCapDone;
begin
  $display("checking Capture");
	fork
		begin: timeout1
			repeat(70000) @(posedge clk);
			$display("ERROR: timeout due to lack of response");
			$stop();
		end	
		begin
			sndcmd({RD,TRIG_CFG,8'h00});
			while (resp[5] == 0) begin
			  @(posedge resp_rdy);
			  clr_resp_rdy = 1; // assert clr_resp_rdy, kick down resp_rdy
			  repeat (2) @(negedge clk);
			  clr_resp_rdy = 0; // assert clr_resp_rdy, kick down resp_rdy
			  sndcmd({RD,TRIG_CFG,8'h00});
			end
			@(posedge resp_rdy);
			clr_resp_rdy = 1; // assert clr_resp_rdy, kick down resp_rdy
			repeat (2) @(negedge clk);
			clr_resp_rdy = 0; // assert clr_resp_rdy, kick down resp_rdy
			disable timeout1;
			$display("Capture Done!");
		end					
	join
end
endtask
