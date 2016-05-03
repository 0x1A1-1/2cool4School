
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
		strt_tx = 1;

		RST_n = 1;
		repeat (2) @(negedge REF_CLK);
		RST_n = 0;
		repeat (2) @(negedge REF_CLK);
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
	repeat (2) @(negedge clk);
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
			else begin
				$display("response received but incorrect");
				//$stop;
			end
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

task readWrite;
	begin
	  //simple test, omly read/write
	  
	  //initialize design
	  strt_tx = 0;
	  initialize;
	 
	  //first test: writing to trig_cfg and read from trig_cfg
	  repeat(10) @ (negedge clk); 
	  sndcmd({WR,TRIG_CFG, 8'h16});
	  chkresp(8'hA5);
	  
	  //wrong cmd test
	  repeat(10) @ (negedge clk); 
	  sndcmd({2'b11,VIH, 8'h46});
	  chkresp(8'hEE);
	  
	  //change trig_pos
	  repeat(10) @ (negedge clk);   
	  sndcmd({WR,TRIG_POS_H,8'b0111_1111});
	  chkresp(8'hA5);
	  sndcmd({WR,TRIG_POS_L,8'hff});
	  chkresp(8'hA5);
		
	  //change VIH,VIL
	  repeat(10) @ (negedge clk);   
	  sndcmd({WR,VIH,8'hff});
	  chkresp(8'hA5);
	  sndcmd({WR,VIL,8'h00});
	  chkresp(8'hA5);
	  
	  //change CHxTrigCfg
	  repeat(10) @ (negedge clk);   
	  sndcmd({WR,CH1TRIG_CFG,8'b0001_1111});
	  chkresp(8'hA5);
	  repeat(10) @ (negedge clk); 
	  sndcmd({WR,CH2TRIG_CFG,8'h16});
	  chkresp(8'hA5);
	  
	  
	  //read what we just put in
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,TRIG_POS_H, 8'h00});
	  chkresp(8'b0111_1111);
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,TRIG_POS_L, 8'h00});
	  chkresp(8'hff);
	  repeat(10) @ (negedge clk);   
	  sndcmd({RD,TRIG_CFG, 8'h00});
	  chkresp(8'h16);
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,CH1TRIG_CFG, 8'h00});
	  chkresp(8'b0001_1111); 
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,CH2TRIG_CFG, 8'h00});
	  chkresp(8'h16);
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,CH3TRIG_CFG, 8'h00});
	  chkresp(8'b01); 
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,CH4TRIG_CFG, 8'h00});
	  chkresp(8'h01);
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,CH5TRIG_CFG, 8'h00});
	  chkresp(8'h01);
	  
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,DECIM, 8'h00});
	  chkresp(8'h00);
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,VIL, 8'h00});
	  chkresp(8'b00); 
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,VIH, 8'h00});
	  chkresp(8'hff);
	  
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,MTCH_H, 8'h00});
	  chkresp(8'h00);
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,MTCH_L, 8'h00});
	  chkresp(8'h00);
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,BAUD_CNT_H, 8'h00});
	  chkresp(8'h06); 
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,BAUD_CNT_L, 8'h00});
	  chkresp(8'hC8);
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,MSK_H, 8'h00});
	  chkresp(8'h00);
	  repeat(10) @ (negedge clk);
	  sndcmd({RD,MSK_L, 8'h00});
	  chkresp(8'h00);
	  
	   repeat(10) @ (negedge clk);
	   sndcmd({RD,8'hff, 8'h00});
	   chkresp(8'hEE);
	   repeat(10) @ (negedge clk);
	   sndcmd({WR,8'hff, 8'h00});
	   chkresp(8'hEF);
	end
endtask

task capTriDum;  //second test: channel capture, triggering, dumping test
	begin

	  //initialize design
	  strt_tx = 0;
	  initialize;
	 
	  //set trigcfg to disable UART, SPI Triggering
	  repeat(10) @ (negedge clk); 
	  sndcmd({WR,TRIG_CFG, 8'b0001_0011});  
	  chkresp(8'hA5);
	  
	  sndcmd({WR,DECIM,8'h02});
	  chkresp(8'hA5);

	  //set CH1TrigCfg pos_edge, Ch2 Neg edge, CH3 High level, CH4 Low Level, CH5 dont care
	  repeat(10) @ (negedge clk); 
	  sndcmd({WR,CH1TRIG_CFG, 8'b0000_1000});
	  chkresp(8'hA5);
	  repeat(10) @ (negedge clk); 	
	  sndcmd({WR,CH2TRIG_CFG, 8'b0000_1000}); 
	  chkresp(8'hA5);
	  repeat(10) @ (negedge clk);   
	  sndcmd({WR,CH3TRIG_CFG, 8'b0000_1000});
	  chkresp(8'hA5);
	  repeat(10) @ (negedge clk);  
	  sndcmd({WR,CH4TRIG_CFG, 8'b0000_1000});
	  chkresp(8'hA5);
	  repeat(10) @ (negedge clk);  
	  sndcmd({WR,CH5TRIG_CFG, 8'b0000_1000});
	  chkresp(8'hA5);  
  
	end
endtask

task decTriPos;
	begin
	  
	  //initialize design
	  strt_tx = 0;
	  initialize;
	 
	  //third test: channel capture, triggering, dumping test, but also changes decimator, and trig_pos number
	 
	  //set trigcfg to disable UART, SPI Triggering
	  sndcmd({WR,TRIG_CFG, 8'b001_0011});  
	  chkresp(8'hA5);  
	  

	  //set CH1TrigCfg pos_edge, Ch2 Neg edge, CH3 High level, CH4 Low Level, CH5 dont care
	  repeat(10) @ (negedge clk); 
	  sndcmd({WR,CH1TRIG_CFG, 8'b0000_1000});
	  chkresp(8'hA5);
	  repeat(10) @ (negedge clk); 	
	  sndcmd({WR,CH2TRIG_CFG, 8'b0000_1000}); 
	  chkresp(8'hA5);
	  repeat(10) @ (negedge clk);   
	  sndcmd({WR,CH3TRIG_CFG, 8'b0000_1000});
	  chkresp(8'hA5);
	  repeat(10) @ (negedge clk);  
	  sndcmd({WR,CH4TRIG_CFG, 8'b0000_1000});
	  chkresp(8'hA5);
	  repeat(10) @ (negedge clk);  
	  sndcmd({WR,CH5TRIG_CFG, 8'b0000_1000});
	  chkresp(8'hA5);    
	  
	  //set decimator & trig_pos
	  repeat(10) @ (negedge clk);
	  sndcmd({WR,DECIM, 8'b0000_0001}); 
	  chkresp(8'hA5); 
	  repeat(10) @ (negedge clk);
	  sndcmd({WR,DECIM, 8'b0000_0010}); 
	  chkresp(8'hA5); 
	  repeat(10) @ (negedge clk);
	  sndcmd({WR,DECIM, 8'b0000_0011}); 
	  chkresp(8'hA5); 
	  repeat(10) @ (negedge clk);
	  sndcmd({WR,DECIM, 8'b0000_0100}); 
	  chkresp(8'hA5); 
	  repeat(10) @ (negedge clk);
	  sndcmd({WR,DECIM, 8'b0000_0101}); 
	  chkresp(8'hA5); 
	  repeat(10) @ (negedge clk);
	  sndcmd({WR,DECIM, 8'b0000_0110}); 
	  chkresp(8'hA5); 
	  repeat(10) @ (negedge clk);
	  sndcmd({WR,DECIM, 8'b0000_0111}); 
	  chkresp(8'hA5); 
	  repeat(10) @ (negedge clk);
	  sndcmd({WR,DECIM, 8'b0000_1000}); 
	  chkresp(8'hA5); 
	  repeat(10) @ (negedge clk);
	  sndcmd({WR,DECIM, 8'b0000_1001}); 
	  chkresp(8'hA5); 
	  repeat(10) @ (negedge clk);
	  sndcmd({WR,TRIG_POS_H, 8'b0000_1111});
	  chkresp(8'hA5); 
	  repeat(10) @ (negedge clk);  
	  sndcmd({WR,TRIG_POS_L, 8'b1111_0000}); 
	  chkresp(8'hA5);  

	end
endtask

task UARTRIG;
	begin
		//initialize design
		strt_tx = 0;
		initialize;

		//forth test: UART TRIGGER, so bit0 of trigcfg should be 0
		repeat(10) @ (negedge clk);
		sndcmd({WR,TRIG_CFG, 8'b0001_0010});
		chkresp(8'hA5);
		repeat(10) @ (negedge clk);
		sndcmd({WR,BAUD_CNT_H, 8'b0001_0010});
		chkresp(8'hA5);
		repeat(10) @ (negedge clk);
		sndcmd({WR,BAUD_CNT_L, 8'b0001_0010});
		chkresp(8'hA5);
		repeat(10) @ (negedge clk);
		sndcmd({WR,MSK_L, 8'b0000_1111});
		chkresp(8'hA5);
		repeat(10) @ (negedge clk);
		sndcmd({WR,MTCH_L, 8'b1111_0000});
		chkresp(8'hA5);

	end
endtask

task SPITRIG;
	begin
		// openning dump file to write
		fptr1 = $fopen("CH1dmp.txt","w");
		fptr2 = $fopen("CH2dmp.txt","w");
		fptr3 = $fopen("CH3dmp.txt","w");
		fptr4 = $fopen("CH4dmp.txt","w");
		fptr5 = $fopen("CH5dmp.txt","w");
		
		//initialize design
		strt_tx = 0;
		initialize;

		//fifth test: SPI TRIGGER, so bit1 of trigcfg should be 0, bit2 for 8_16, bit3 for edg
		repeat(10) @ (negedge clk);
		sndcmd({WR,TRIG_CFG, 8'b0001_1101});
		chkresp(8'hA5);
		repeat(10) @ (negedge clk);
		sndcmd({WR,BAUD_CNT_H, 8'b0001_0010});
		chkresp(8'hA5);
		repeat(10) @ (negedge clk);
		sndcmd({WR,BAUD_CNT_L, 8'b0001_0010});
		chkresp(8'hA5);
		repeat(10) @ (negedge clk);
		sndcmd({WR,MSK_H, 8'b0000_1111});
		chkresp(8'hA5);
		repeat(10) @ (negedge clk);
		sndcmd({WR,MSK_L, 8'b0000_1111});
		chkresp(8'hA5);
		repeat(10) @ (negedge clk);
		sndcmd({WR,MTCH_H, 8'b1111_0000});
		chkresp(8'hA5);
		repeat(10) @ (negedge clk);
		sndcmd({WR,MTCH_L, 8'b1111_0000});
		chkresp(8'hA5);
		  
		//dump test
		PollCapDone;

		sndcmd({DUMP,DPCH1, 8'h00});
		dump(DPCH1);
		sndcmd({DUMP,DPCH2, 8'h00});
		dump(DPCH2);
		sndcmd({DUMP,DPCH3, 8'h00});
		dump(DPCH3);
		sndcmd({DUMP,DPCH4, 8'h00});
		dump(DPCH4);
		sndcmd({DUMP,DPCH5, 8'h00});
		dump(DPCH5);

		$fclose(fptr1);
		$fclose(fptr2); 
		$fclose(fptr3);
		$fclose(fptr4);
		$fclose(fptr5); 
    
	end
endtask