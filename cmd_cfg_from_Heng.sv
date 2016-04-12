module cmd_cfg();

	parameter ENTRIES = 384;
			  LOG2 = 9;			  
	
	input clk, rst_n; //system clk and rst_n
	input [15:0] cmd; //16 bits cmd from UART.The upper 2-bits [15:14] encodes the opcode
	input cmd_rdy; //cmd is ready for use
	input resp_sent; // asserted when transmission of resp to host is finished
	input rd_done; // asserted when last bite of sample data has been read
	input set_capture_done; // sets capture done bit
	input [7:0] rdataCH1, rdataCH2, rdataCH3, rdataCH4, rdataCH5;
	
	//register set
	output reg [5:0] TrigCfg;
	output reg [4:0] CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg;
	output reg [3:0] decimator;
	output reg [7:0] VIH, VIL;
	output reg [7:0] matchH, matchL;
	output reg [7:0] maskH, maskL;
	output reg [7:0] baud_cntH, baud_cntL;
	output [LOG2-1:0] trig_posH, trig_posL;
	
	output [7:0] resp; //data send to host as response
	output send_resp; //initiate transmission to host
	output clr_cmd_rdy; // used when processing finished
	output strt_rd; //fire off a read of channel RAMs
	
	logic wrt_reg;//asserted when write reg happens
	logic rd_add; //read address
	logic wrt_add; //write address
	logic wrt_data; //data to be write
	
	assign rd_add = cmd[13:8];
	assign wrt_add = cmd[13:8];
	assign wrt_data = cmd[7:0];
	
	//TrigCfg ff
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)
			TrigCfg <= 6'h03;
		else if (wrt_reg && wrt_add == 2'h00)
			TrigCfg <= wrt_data[5:0];
			
	//CH1TrigCfg ff		
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			CH1TrigCfg <= 5'h01;
		else if (wrt_reg && wrt_add == 2'h01)
			CH1TrigCfg <= wrt_data[4:0];
			
	//CH2TrigCfg ff	
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			CH2TrigCfg <= 5'h01;
		else if (wrt_reg && wrt_add == 2'h02)
			CH2TrigCfg <= wrt_data[4:0];
			
	//CH3TrigCfg ff	
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			CH3TrigCfg <= 5'h01;
		else if (wrt_reg && wrt_add == 2'h03)
			CH3TrigCfg <= wrt_data[4:0];
			
	//CH4TrigCfg ff		
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			CH4TrigCfg <= 5'h01;
		else if (wrt_reg && wrt_add == 2'h04)
			CH4TrigCfg <= wrt_data[4:0];	

	//CH5TrigCfg ff	
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			CH5TrigCfg <= 5'h01;
		else if (wrt_reg && wrt_add == 2'h05)
			CH5TrigCfg <= wrt_data[4:0];	
			
	//decimator ff	
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)	
			decimator <= 4'h0;
		else if (wrt_reg && wrt_add == 2'h06)
			decimator <= wrt_data[3:0];
	
	//VIH ff
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			VIH <= 8'hAA;
		else if (wrt_reg && wrt_add == 2'h07)
			VIH <= wrt_data;
			
	//VIL ff
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			VIL <= 8'h55;
		else if (wrt_reg && wrt_add == 2'h08)
			VIL <= wrt_data;
			
	//matchH ff
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			matchH <= 8'h00;
		else if (wrt_reg && wrt_add == 2'h09)
			matchH <= wrt_data;
			
	//matchL ff
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			matchL <= 8'h00;
		else if (wrt_reg && wrt_add == 2'h0A)
			matchL <= wrt_data;
			
	//maskH ff
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			maskH <= 8'h00;
		else if (wrt_reg && wrt_add == 2'h0B)
			maskH <= wrt_data;	
	//maskL ff
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			maskL <= 8'h00;
		else if (wrt_reg && wrt_add == 2'h0C)
			maskL <= wrt_data;
			
	//baud_cntH ff
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			baud_cntH <= 8'h06;
		else if (wrt_reg && wrt_add == 2'h0D)
			baud_cntH <= wrt_data;
			
	//baud_cntL ff
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)		
			baud_cntL <= 8'hC8;
		else if (wrt_reg && wrt_add == 2'h0E)
			baud_cntL <= wrt_data;	
			
	//trig_posH ff
	always_ff @ (posedge clk, negedge rst_n)
		if(!rst_n)
			trig_posH < =8'h00;
		else if (wrt_reg && wrt_add == 2'h0F)
			trig_posH <= wrt_data;
			
	//trig_posL ff
	always_ff @ (posedge clk, negedge rst_n)
		if(!rst_n)
			trig_posL < =8'h01;	
		else if (wrt_reg && wrt_add == 2'h10)
			trig_posL <= wrt_data;	
			
			
	//main FSM	
	logic [2:0] dmp_chnnl;//dump channel reading
	logic [1:0] Op; //opcode from cmd[15:14]
	assign Op = cmd[15:14];
	assign dmp_chnnl = cmd[10:8];
	
	typedef enum reg [2:0] {IDLE,POS_ACK,DUMP, DUMPING, NEG_ACK} state_t;
	state_t state, nxt_state;
	
	always_ff @ (posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state
			
	//FSM main body
	always_comb begin
		//set default values
		wrt_reg = 0;
		send_resp = 0;
		resp = 8'bxxxx_xxxx;
		nxt_state = IDLE;
		clr_cmd_rdy = 0;
		strt_rd = 0;
		
		case(state)
			IDLE : 
				//processing part
				if(cmd_rdy) begin
					case(Op)
					
						2'b00: begin//Read 
							case(rd_add):
								2'h01: resp = {3'b000, CH1TrigCfg};
								2'h02: resp = {3'b000, CH2TrigCfg};
								2'h03: resp = {3'b000, CH3TrigCfg};
								2'h04: resp = {3'b000, CH4TrigCfg};
								2'h05: resp = {3'b000, CH5TrigCfg};		
								2'h06: resp = {4'b000, decimator};
								2'h07: resp = VIH;
								2'h08: resp = VIL;
								2'h09: resp = matchH;
								2'h0A: resp = matchL;
								2'h0B: resp = maskH;	
								2'h0C: resp = maskL;
								2'h0D: resp = baud_cntH;
								2'h0E: resp = baud_cntL;
								2'h0F: resp = trig_posH; 
								2'h10: resp = trig_posL;
								default: resp = ={2'b00, TrigCfg};
							endcase		
							nxt_state = IDLE;	
							clr_cmd_rdy = 1;
							send_resp = 1;
						end
						
						2'b01: begin //write
							wrt_reg = 1;
							nxt_state = POS_ACK;
						end	
						
						2'b10: begin //dump
							nxt_state = DUMP;
							strt_rd = 1;
						end
						
						default: begin //reserved for future use
							nxt_state = NEG_ACK;							
						end
			
					endcase //endcase Op
				end else
				nxt_state = IDLE;
				
			POS_ACK: begin// after write data, send back 0XA5 pos ack
				resp = 2'hA5;
				send_resp = 1;
				clr_cmd_rdy = 1;
				nxt_state = IDLE;
				end

			DUMP: begin //dump state
				
				case(dmp_chnnl)
					3'b001: resp = rdataCH1;
					3'b010: resp = rdataCH2;
					3'b011: resp = rdataCH3;
					3'b100: resp = rdataCH4;
					default: resp = rdataCH5;//default reading CH5
				endcase
				
				if(rd_done) begin // when last bit is read, jump out of DUMP state
					clr_cmd_rdy = 1;
					nxt_state =IDLE;
				end else begin
					nxt_state =DUMPING;
					send_resp =1;
				end
			end
			
			DUMPING: begin //dumping continuing here
			//the difference to DUMP is since send_resp can only assert one time
			//in the started of transmitting, but need to keep on this state
				if (resp_sent) begin
					nxt_state =DUMP;
				end else begin
					nxt_state = DUMPING;//waiting and looping here until resp_sent finished
				end
			end
			
			default: begin //when none, send back neg ack 0XEE
				resp = 2'hEE;
				send_resp = 1;
				nxt_state = IDLE;
				clr_cmd_rdy = 1;
				end

			
endmodule


