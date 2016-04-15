module cmd_cfg_tb();

	parameter ENTRIES = 384, LOG2 = 9;	

	logic [15:0] cmd;//16 bits cmd from UART.The upper 2-bits [15:14] encodes the opcode 
	logic clk, rst_n;//logic inputs for cmd_cfg

	logic cmd_rdy; //cmd is ready for use 
	logic resp_sent; // asserted when transmission of resp to host is finished 
	logic set_capture_done; // sets capture done bit 
	logic [LOG2 -1:0] ram_addr;// address from cntrl
	//logic for cmd_cfg outputs

	logic [5:0] TrigCfg; 
	logic [4:0] CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg; 
	logic [3:0] decimator; 
	logic [7:0] VIH, VIL; 
	logic [7:0] matchH, matchL; 
	logic [7:0] maskH, maskL; 
	logic [7:0] baud_cntH, baud_cntL; 
	logic [LOG2-1:0] trig_posH, trig_posL; 
	logic [7:0] response; //data send to host as response 
	logic send_resp; //initiate transmission to host 
	logic clr_cmd_rdy; // used when processing finished 
	logic [LOG2-1: 0] addr_ptr;//used inside FSM, and also for as output raddr for RAM

	logic [7:0] rdataCH1, rdataCH2, rdataCH3, rdataCH4, rdataCH5;//connecting from CMD to RAM
	
	//logic for CommMaster
	logic [15:0] mst_cmd;
	logic snd_cmd;

	//logic for Ram Queue Interface We are only going to test with 1 Ram Queue
	logic we;
	logic [7:0] wdata;
	logic [LOG2 -1:0] waddr;
	
	//UART and cmonmaster
	logic RX_TX, TX_RX;
	logic [7:0] result;
	
	//interger for looping
	integer i, j;

	//expected value from dump
	logic [7:0] expected;
	
	//clear signal after testing
	reg clr_rdy ;			
				
	//All five channels are hooked up to one ram queue
	cmd_cfg iCMD(.clk(clk), .rst_n(rst_n), .cmd(cmd), .cmd_rdy(cmd_rdy), .resp_sent(resp_sent), .set_capture_done(set_capture_done), 
				.rdataCH1(rdataCH1), .rdataCH2(rdataCH2), .rdataCH3(rdataCH3), .rdataCH4(rdataCH4), .rdataCH5(rdataCH5), 
				.TrigCfg(TrigCfg), .CH1TrigCfg(CH1TrigCfg), .CH2TrigCfg(CH2TrigCfg), .CH3TrigCfg(CH3TrigCfg), .CH4TrigCfg(CH4TrigCfg),
				.CH5TrigCfg(CH5TrigCfg), .decimator(decimator), .VIH(VIH), .VIL(VIL), .maskH(maskH), .maskL(maskL), .matchH(matchH), .matchL(matchL),
				.baud_cntH(baud_cntH), .baud_cntL(baud_cntL), .trig_posH(trig_posH), .trig_posL(trig_posL),
				.resp(response), .send_resp(send_resp), .clr_cmd_rdy(clr_cmd_rdy), .ram_addr(ram_addr), .addr_ptr(addr_ptr));
	
	//instantiate all 5 RAM block
	RAMqueue iRAM1(.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(addr_ptr), .rdata(rdataCH1));
	RAMqueue iRAM2(.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(addr_ptr), .rdata(rdataCH2));
	RAMqueue iRAM3(.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(addr_ptr), .rdata(rdataCH3));
	RAMqueue iRAM4(.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(addr_ptr), .rdata(rdataCH4));
	RAMqueue iRAM5(.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(addr_ptr), .rdata(rdataCH5));
	

	//UART_Wrapper
	UART_wrapper UART(.clk(clk), .rst_n(rst_n), .resp(response), .send_resp(send_resp), .clr_cmd_rdy(clr_cmd_rdy),
						.RX(TX_RX), .TX(RX_TX), .resp_sent(resp_sent), .cmd_rdy(cmd_rdy), .cmd(cmd));
	//CommMaster 
	CommMaster CMD_MST(.clk(clk), .rst_n(rst_n), .cmd(mst_cmd), .snd_cmd(snd_cmd), .TX(TX_RX), .cmd_cmplt(), .RX(RX_TX), 
						.rdy(result_rdy), .rx_data(result), .clr_rdy(clr_rdy));
	
	//manipulating input cmd and look on output resp
	always #1 clk=~clk;
	
	//time out setting
	initial begin
		repeat(5000000) @(posedge clk);
		$stop(); 
	end 
	
	initial begin
		rst_n = 0;
		clk = 0;
		clr_rdy = 0;
		@(posedge clk); @(negedge clk); rst_n = 1;
	
		// write to maskH #AF
		mst_cmd = 16'b01_001011_10101111;
		snd_cmd = 1;@(posedge clk); snd_cmd = 0;
		@(posedge result_rdy); 
		if(result == 8'hA5) $display("Got the correct response for write!");
		else $display("Didn't get ack from cmd_cfg"); 
		clr_rdy = 1; @(posedge clk); clr_rdy = 0;
		
		// write to wrong address
		mst_cmd = 16'b01_101011_10101111;
		snd_cmd = 1;@(posedge clk); snd_cmd = 0;
		@(posedge result_rdy); 
		if(result == 8'hEE) $display("Got the correct response for wrong write!");
		else $display("No you are supposed to give me error"); 
		clr_rdy = 1; @(posedge clk); clr_rdy = 0;
		
		// read maskH from the RAM
		mst_cmd = 16'b00_001011_00000000;
		snd_cmd = 1;@(posedge clk); snd_cmd = 0;
		
		@(posedge result_rdy); 		
		if(result == 8'hAF) $display("Got the correct date from READ!");
		else $display("Didn't get correct value from maskH register"); //ERROR
		clr_rdy = 1; @(posedge clk); clr_rdy = 0;
		
		// read wrong address from the RAM
		mst_cmd = 16'b00_101100_00000000;
		snd_cmd = 1;@(posedge clk); snd_cmd = 0;
		
		@(posedge result_rdy); 		
		if(result == 8'hEE) $display("Got the correct response for wrong read!");
		else $display("No you are supposed to give me error"); //ERROR
		clr_rdy = 1; @(posedge clk); clr_rdy = 0;
		
		
		// DUMP Checking
		mst_cmd = 16'b10_000001_00000000;
		ram_addr = 0;
		snd_cmd = 1; @(posedge clk); snd_cmd = 0;
		for(j = 0; j < 384; j = j + 1) begin
			//checking dump of every address
			@(posedge result_rdy);
			expected = j+1 % 384;
			//display error message
			if(result != expected) begin
				$display("Got the wrong response!"); 
				$stop;
			end
		end
		//Display test passed message
		@(posedge clr_cmd_rdy) begin
				$display("Dumping all passed!"); 
				$stop;
		end
		
		
		repeat (10) @(posedge clk);
	end
	
	//initialize a testing RAM queue
	initial begin
 		waddr = 0;
 		wdata = 8'h00;
 		repeat (2) @(posedge clk);
 		//write some data to ram queue
 		we = 1;
 		for(i = 0; i < 384; i = i + 1)begin
 			waddr = waddr + 1;
			wdata = wdata + 1 % 384;
 			repeat (1) @(posedge clk);
 		end
 		we = 0;
 	end
 	
endmodule
