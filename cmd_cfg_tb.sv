module cmd_cfg_tb();

parameter ENTRIES = 384, LOG2 = 9;	

logic [15:0] cmd;//16 bits cmd from UART.The upper 2-bits [15:14] encodes the opcode 
logic clk, rst_n;
//logic inputs for cmd_cfg
logic cmd_rdy; //cmd is ready for use 
logic resp_sent; // asserted when transmission of resp to host is finished 
logic set_capture_done; // sets capture done bit 
logic [LOG2 -1:0] ram_addr;// address from cntrl
logic [7:0] rdata; //data from the ram queue

//logic for cmd_cfg outputs
logic [5:0] TrigCfg; 
logic [4:0] CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg; 
logic [3:0] decimator; 
logic [7:0] VIH, VIL; 
logic [7:0] matchH, matchL; 
logic [7:0] maskH, maskL; 
logic [7:0] baud_cntH, baud_cntL; 
logic [LOG2-1:0] trig_posH, trig_posL; 
logic [7:0] resp; //data send to host as response 
logic send_resp; //initiate transmission to host 
logic clr_cmd_rdy; // used when processing finished 
logic [LOG2-1: 0] addr_ptr;//used inside FSM, and also for as output raddr for RAM

//logic for CommMaster
//we dont need to retest commaster and uartwrapper

//logic for Ram Queue We are only going to test with 1 Ram Queue
logic we;
logic [7:0] wdata;
logic [LOG2 -1:0] waddr, raddr;
			
//Testing Logic
logic [7:0] test_response;
			
//All five channels are hooked up to one ram queue
cmd_cfg iCMD(.clk(clk), .rst_n(rst_n), .cmd(cmd), .cmd_rdy(cmd_rdy), .resp_sent(), .set_capture_done(set_capture_done), 
			.rdataCH1(rdata), .rdataCH2(rdata), .rdataCH3(rdata), .rdataCH4(rdata), .rdataCH5(rdata), .ram_addr(raddr), 
			.TrigCfg(), .CH1TrigCfg(), .CH2TrigCfg(), .CH3TrigCfg(), .CH4TrigCfg(), .CH5TrigCfg(), 
			.decimator(), .VIH(), .VIL(), .maskH(), .maskL(), .baud_cntH(), .baud_cntL(),.trig_posH(), 
			.trig_posL(), .resp(resp), .send_resp(), .clr_cmd_rdy(clr_cmd_rdy), .ram_addr(ram_addr), .addr_ptr());
			

RAMqueue iRAM(.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(raddr), .rdata(rdata));


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
			
endmodule
