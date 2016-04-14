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
				
	//Testing Logic
	logic [7:0] test_response;
	
	//UART and cmonmaster
	logic RX_TX, TX_RX;
	logic [7:0] result;

	logic [7:0] RAM[3:0];
	integer i, j;

	logic [7:0] expected;
	reg clr_rdy ;			
				
	//All five channels are hooked up to one ram queue
	cmd_cfg iCMD(.clk(clk), .rst_n(rst_n), .cmd(cmd), .cmd_rdy(cmd_rdy), .resp_sent(resp_sent), .set_capture_done(set_capture_done), 
				.rdataCH1(rdataCH1), .rdataCH2(rdataCH2), .rdataCH3(rdataCH3), .rdataCH4(rdataCH4), .rdataCH5(rdataCH5), 
				.TrigCfg(TrigCfg), .CH1TrigCfg(CH1TrigCfg), .CH2TrigCfg(CH2TrigCfg), .CH3TrigCfg(CH3TrigCfg), .CH4TrigCfg(CH4TrigCfg),
				.CH5TrigCfg(CH5TrigCfg), .decimator(decimator), .VIH(VIH), .VIL(VIL), .maskH(maskH), .maskL(maskL), .matchH(matchH), .matchL(matchL),
				.baud_cntH(baud_cntH), .baud_cntL(baud_cntL), .trig_posH(trig_posH), .trig_posL(trig_posL),
				.resp(response), .send_resp(send_resp), .clr_cmd_rdy(clr_cmd_rdy), .ram_addr(ram_addr), .addr_ptr(addr_ptr));
				
	RAMqueue iRAM1(.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(addr_ptr), .rdata(rdataCH1));
	//RAMqueue iRAM2(.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(addr_ptr), .rdata(rdataCH2));
	//RAMqueue iRAM3(.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(addr_ptr), .rdata(rdataCH3));
	//RAMqueue iRAM4(.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(addr_ptr), .rdata(rdataCH4));
	//RAMqueue iRAM5(.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(addr_ptr), .rdata(rdataCH5));
	

	//UART_Wrapper
	UART_wrapper UART(.clk(clk), .rst_n(rst_n), .resp(response), .send_resp(send_resp), .clr_cmd_rdy(clr_cmd_rdy),
						.RX(TX_RX), .TX(RX_TX), .resp_sent(resp_sent), .cmd_rdy(cmd_rdy), .cmd(cmd));
	//CommMaster 
	CommMaster CMD_MST(.clk(clk), .rst_n(rst_n), .cmd(mst_cmd), .snd_cmd(snd_cmd), .TX(TX_RX), .cmd_cmplt(), .RX(RX_TX), 
						.rdy(result_rdy), .rx_data(result), .clr_rdy(clr_rdy));
	
	//manipulating input cmd and look on output resp
	initial begin
		clk = 0;
		rst_n = 0;
		i = 0; 
		@(posedge clk); @(negedge clk); rst_n = 1;
		@(posedge clk);

		//cmd = WRITE maskH with AF and wait for pos ack
		mst_cmd = 16'b01_001011_10101111; //4BAF
		snd_cmd = 1; repeat(2)@(posedge clk); snd_cmd = 0;

		@(posedge result_rdy);
		if(response == 8'hA5) $display("Got the correct response!");
		else $display("Didn't get ack from cmd_cfg"); //ERROR

		repeat(1000) @(posedge clk);
		
		//cmd = READ maskH
		mst_cmd = 16'b00_001011_00000000;
		snd_cmd = 1; @(posedge clk); snd_cmd = 0;

		@(posedge send_resp);
		if(response == 8'hAF) $display("Got the correct response!");
		else $display("Didn't get correct value from maskH register"); //ERROR
	
		repeat(1000) @(posedge clk);

		//cmd = DUMP channel 1 (only RAM we have in this tb)
		mst_cmd = 16'b10_000001_00000000;
		ram_addr = 0;
		snd_cmd = 1; @(posedge clk); snd_cmd = 0;


		for(j = 0; j < 384; j = j + 1) begin
			//if(j < 383)
			@(posedge send_resp);
			expected = j+1 % 384;
			if(response != expected) $stop;
			else if(clr_cmd_rdy) $stop;
		end

		@(posedge clr_cmd_rdy);
		$stop;

		
	end
	
	always #1 clk = ~clk;
	
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

	initial begin
		repeat(5000000) @(posedge clk);
		$stop(); //Boo
	end
	
	/***************************
	logic [8:0] i;
	//we still need a RAMqueue interface...Pontentially in capture?
	initial begin 
		$monitor("response: %b", resp);
	end

	initial begin 
	clk = 0;
	we = 0;
	cmd_rdy = 0;
	rst_n = 0;
	resp_sent = 0;
	set_capture_done = 0;
	waddr_ctr = 8'h00;
	waddr = 0;
	wdata = 8'h00;

	repeat (2) @(posedge clk);
	//write some data to ram queue
	we = 1;
	for(i = 0; i < 384; i = i + 1)begin
		waddr = waddr + 1;
		wdata = wdata + 1;
		repeat (1) @(posedge clk);
	end
	we = 0;

	//write to a reg MaskH 0x4B55
	cmd = 16'b0100101101010101;
	repeat (2) @(posedge clk);
	cmd_rdy = 1;
	//wait for the all clear
	while(!clr_cmd_rdy)
		repeat (1) @(posedge clk);
		
		
	//read reg MaskH
	//cmd = 16'h0B55;
	cmd = 16'b0000101101010101;
	repeat (2) @(posedge clk);
	cmd_rdy = 1;	

	while(!clr_cmd_rdy)
		repeat (1) @(posedge clk);	

	if(resp == 8'h55)
		$display("write and read worked worked!");

	//dump channel 1
	//cmd = 16'h8100;
	cmd = 16'b1000000100000000;
	repeat (2) @(posedge clk)
	cmd_rdy = 1;

	while(!clr_cmd_rdy)
		repeat (1) @(posedge clk);

		
	$display("cmd_cfg is functional :)");
	$stop(); //passed

	end

	//forces cmd_rdy to 0 when clr_cmd_rdy is asserted
	always @(posedge clr_cmd_rdy) cmd_rdy = 0;

	always #5 clk = ~clk;

	//timeout
	initial begin
		repeat(500000) @(posedge clk);
		$stop(); //Boo
	end
	******************************/			
endmodule
