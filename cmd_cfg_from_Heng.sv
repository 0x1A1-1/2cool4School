module cmd_cfg(clk, rst_n, cmd, cmd_rdy, resp_sent, rd_done, set_capture_done, rdataCH1,rdataCH2, rdataCH3, rdataCH4,
		rdataCH5, ram_addr, TrigCfg, CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg, decimator, VIH,
		VIL, matchH, matchL, maskH, maskL, baud_cntH, baud_cntL, trig_posH, trig_posL, resp, send_resp, clr_cmd_rdy,
		strt_rd); //put list in here 
 
	parameter ENTRIES = 384, LOG2 = 9;	 
 	 
 	localparam RD = 2'b00; //RD indicates read Opcode
 	localparam WR = 2'b01; //WR indicates write Opcode
 	localparam DMP = 2'b10; // DMP indicates dump Opcode
 	 
 	input clk, rst_n; //system clk and rst_n 
 	input [15:0] cmd; //16 bits cmd from UART.The upper 2-bits [15:14] encodes the opcode 
 	input cmd_rdy; //cmd is ready for use 
 	input resp_sent; // asserted when transmission of resp to host is finished 
 	input set_capture_done; // sets capture done bit 
 	input [7:0] rdataCH1, rdataCH2, rdataCH3, rdataCH4, rdataCH5;//Read Data From RAM 
 
 
 	//ram address is same across all 5 queues 
 	//output from capture_cntrl block 
 	input [LOG2-1:0] ram_addr; //last valid addr written to ram. read from this value + 1 to ram_addr (wrap around @ ENTRIES) 
 	 
 	//register set 
 	output logic [5:0] TrigCfg; 
 	output logic [4:0] CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg; 
 	output logic [3:0] decimator; 
 	output logic [7:0] VIH, VIL; 
 	output logic [7:0] matchH, matchL; 
 	output logic [7:0] maskH, maskL; 
 	output logic [7:0] baud_cntH, baud_cntL; 
 	output logic [LOG2-1:0] trig_posH, trig_posL; 
 	 
 	output logic [7:0] resp; //data send to host as response 
 	output logic send_resp; //initiate transmission to host 
 	output logic clr_cmd_rdy; // used when processing finished 
 
 
 	logic wrt_reg;//asserted when write reg happens 
 	logic [7:0] data; //data to be written 
 	logic [2:0] dmp_chnnl; //dump channel reading 
 	logic [1:0] op; //opcode from cmd[15:14] 
 	logic [5:0] addr; //address from which to read 
	logic [7:0] response;//used by FSM
 	 
 	assign data = cmd[7:0]; 
 	assign dmp_chnnl = cmd[10:8]; 
 	assign op = cmd[15:14]; 
 	assign addr = cmd[13:8]; 
	assign wrt_add = cmd[13:8];
 	 
 	//TrigCfg ff 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n) 
 			TrigCfg <= 6'h03; 
 		else if (wrt_reg && wrt_add == 6'h00) 
 			TrigCfg <= data[5:0]; 
 		else if (set_capture_done)
			TrigCfg[5] <= 1'b1;
 	end 

	
 			 
 	//CH1TrigCfg ff		 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)		 
 			CH1TrigCfg <= 5'h01; 
 		else if (wrt_reg && wrt_add == 6'h01) 
 			CH1TrigCfg <= data[4:0]; 
 	end 
 			 
 	//CH2TrigCfg ff	 
 	always_ff @ (posedge clk, negedge rst_n) begin 
		if (!rst_n)		 
			CH2TrigCfg <= 5'h01; 
 		else if (wrt_reg && wrt_add == 6'h02) 
 			CH2TrigCfg <= data[4:0]; 
 	end 
 			 
 	//CH3TrigCfg ff	 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)		 
 			CH3TrigCfg <= 5'h01; 
 		else if (wrt_reg && wrt_add == 6'h03) 
 			CH3TrigCfg <= data[4:0]; 
 	end 
 			 
 	//CH4TrigCfg ff		 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)		 
 			CH4TrigCfg <= 5'h01; 
 		else if (wrt_reg && wrt_add == 6'h04) 
 			CH4TrigCfg <= data[4:0]; 
 	end	 
 
 	//CH5TrigCfg ff	 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)		 
 			CH5TrigCfg <= 5'h01; 
 		else if (wrt_reg && wrt_add == 6'h05) 
 			CH5TrigCfg <= data[4:0];	 
 	end 
 			 
 	//decimator ff	 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)	 
 			decimator <= 4'h0; 
		else if (wrt_reg && wrt_add == 6'h06) 
 			decimator <= data[3:0]; 
 	end 
 	 
 	//VIH ff 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)		 
 			VIH <= 8'hAA; 
 		else if (wrt_reg && wrt_add == 6'h07) 
 			VIH <= data; 
 	end 
 			 
 	//VIL ff 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)		 
 			VIL <= 8'h55; 
 		else if (wrt_reg && wrt_add == 6'h08) 
 			VIL <= data; 
 	end 
 			 
 	//matchH ff 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)		 
 			matchH <= 8'h00; 
 		else if (wrt_reg && wrt_add == 6'h09) 
 			matchH <= data; 
 	end 
 			 
 	//matchL ff 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)		 
 			matchL <= 8'h00; 
 		else if (wrt_reg && wrt_add == 6'h0A) 
 			matchL <= data; 
 	end 
 			 
 	//maskH ff 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)		 
 			maskH <= 8'h00; 
 		else if (wrt_reg && wrt_add == 6'h0B) 
 			maskH <= data;	 
 	end 
 

 	//maskL ff 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)		 
 			maskL <= 8'h00; 
 		else if (wrt_reg && wrt_add == 6'h0C) 
			maskL <= data; 
 	end 
 			 
 	//baud_cntH ff 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)		 
 			baud_cntH <= 8'h06; 
 		else if (wrt_reg && wrt_add == 6'h0D) 
 			baud_cntH <= data; 
 	end 
 			 
 	//baud_cntL ff 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if (!rst_n)		 
 			baud_cntL <= 8'hC8; 
 		else if (wrt_reg && wrt_add == 6'h0E) 
 			baud_cntL <= data; 
 	end	 
 			 
 	//trig_posH ff 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if(!rst_n) 
 			trig_posH <= 8'h00; 
 		else if (wrt_reg && wrt_add == 6'h0F) 
 			trig_posH <= data; 
 	end 
 			 
 	//trig_posL ff 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if(!rst_n) 
 			trig_posL <= 8'h01;	 
 		else if (wrt_reg && wrt_add == 6'h10) 
 			trig_posL <= data;	 
 	end 
 
 
 	//resp ff 
 	always_ff @(posedge clk, negedge rst_n) begin 
 		if(!rst_n) resp <= 8'h00; 
 		else resp <= response; 
 	end  
 			 
 			 
 	//main FSM		 
 	typedef enum reg [2:0] {IDLE, RESPOND, DUMP, DUMPING} state_t; 
 	state_t state, nxt_state; 
 	 
 	always_ff @ (posedge clk, negedge rst_n) begin 
 		if(!rst_n) 
 			state <= IDLE; 
 		else 
 			state <= nxt_state; 
 	end 
 			 
 	//FSM main body 
 	always_comb begin 
 		//set default values 
 		wrt_reg = 0; 
 		send_resp = 0; 
 		response = 8'h00; //should this default to 00? 
 		nxt_state = IDLE; 
 		clr_cmd_rdy = 0; 
 		strt_rd = 0; 
 		 
 		case(state) 
 			IDLE :  
 				//processing part 
 				if(cmd_rdy) begin 
 					case(op) 
 					 
 						RD: begin //Read  
 							case(addr)								 
 								6'h01: response = {3'b000, CH1TrigCfg}; 
 								6'h02: response = {3'b000, CH2TrigCfg}; 
 								6'h03: response = {3'b000, CH3TrigCfg}; 
 								6'h04: response = {3'b000, CH4TrigCfg}; 
 								6'h05: response = {3'b000, CH5TrigCfg};		 
 								6'h06: response = {4'b000, decimator}; 
 								6'h07: response = VIH; 
 								6'h08: response = VIL; 
 								6'h09: response = matchH; 
 								6'h0A: response = matchL; 
								6'h0B: response = maskH;	 
 								6'h0C: response = maskL; 
 								6'h0D: response = baud_cntH; 
								6'h0E: response = baud_cntL; 
 								6'h0F: response = trig_posH;  
								6'h10: response = trig_posL; 
 								default: response = {2'b00, TrigCfg}; 
							endcase//endcase addr
 							nxt_state = IDLE;	 
							clr_cmd_rdy = 1; 
 							send_resp = 1; 
 						end 
						 
 						WR: begin //write 
							wrt_reg = 1; 
 							 
 							//may need to send ack one clock period later 
							response = 8'hA5; 
 							send_resp = 1; 
 							nxt_state = RESPOND; 
 						end	 
 						 
 						DMP: begin //dump 
							nxt_state = DUMP; 
 						end 
 						 
 						default: begin //reserved for future use 
 							response = 8'hEE; 
 							send_resp = 1; 
 							nxt_state = RESPOND;						 
						end 
 			 
 					endcase //endcase Op 
 				end  
				else 
 					nxt_state = IDLE; 
 				 
 			RESPOND: begin 
 				if(resp_sent) begin  
 					nxt_state = IDLE; 
 					clr_cmd_rdy = 1; 
 				end 
 				else  
 					nxt_state = RESPOND; 
 			end 
 
 			DUMP: begin //dump state 
 				case(dmp_chnnl) 
 					3'b001: response = rdataCH1; 
 					3'b010: response = rdataCH2; 
 					3'b011: response = rdataCH3; 
 					3'b100: response = rdataCH4; 
 					default: response = rdataCH5;//default reading CH5 
 				endcase 
 				 
 				
 				if(rd_done) begin // when last bit is read, jump out of DUMP state 
 					clr_cmd_rdy = 1; 
					nxt_state = IDLE; 
 				end  
 				else begin 
 					nxt_state = DUMPING; 
					send_resp = 1; 
 				end 
 			end 
 			 
 			DUMPING: begin //dumping continuing here 
 			//the difference to DUMP is since send_resp can only assert one time 
 			//in the started of transmitting, but need to keep on this state 
 				if (resp_sent) begin 
 					nxt_state = DUMP; 
 				end else begin 
 					nxt_state = DUMPING;//waiting and looping here until resp_sent finished 
 				end 
 			end 
 			 
 			default: begin //when none, send back neg ack 0XEE 
 				response = 8'hEE; 
 				send_resp = 1; 
 				nxt_state = IDLE; 
 				clr_cmd_rdy = 1; 
 			end 
 
		endcase//endcase state
	end//end FSM
 			 
endmodule 
