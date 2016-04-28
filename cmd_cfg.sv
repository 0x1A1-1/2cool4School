module cmd_cfg(	clk, rst_n, cmd, cmd_rdy, resp_sent, set_capture_done,
				rdataCH1, rdataCH2, rdataCH3, rdataCH4, rdataCH5,
				addr_ptr, ram_addr, decimator,
				TrigCfg, CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg,
				VIH, VIL, matchH, matchL, maskH, maskL, baud_cntH, baud_cntL,
				trig_posH, trig_posL,
				resp, send_resp, clr_cmd_rdy); 

	parameter ENTRIES = 384, LOG2 = 9;	
	
	localparam RD = 2'b00;
	localparam WR = 2'b01;
	localparam DMP = 2'b10;
	
	input clk, rst_n; 					//system clk and rst_n

	///////////////////////////////////////////
	//           INPUTS FROM UART            //
	///////////////////////////////////////////
	input [15:0] cmd; 					//16 bit command from UART 
	input cmd_rdy; 							//cmd is ready for use
	input resp_sent; 						//asserted when transmission of resp to host is finished. Data has been read
	input set_capture_done; 		//sets capture done bit
	
	///////////////////////////////////////////
	//          CHANNEL INPUT DATA           //
	///////////////////////////////////////////
	input [7:0] rdataCH1, rdataCH2, rdataCH3, rdataCH4, rdataCH5;

	///////////////////////////////////////////
	//        INPUTS FROM CAPTURE CTRL       //
	///////////////////////////////////////////
	input logic [LOG2-1:0] ram_addr; 
	
	///////////////////////////////////////////
	//            RAM READ ADDRESS           //
	///////////////////////////////////////////
	output logic [LOG2-1:0] addr_ptr;

	///////////////////////////////////////////
	//        CONFIGURATION REGISTERS        //
	///////////////////////////////////////////
	output logic [5:0] TrigCfg;
	output logic [4:0] CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg;
	output logic [3:0] decimator;
	output logic [7:0] VIH, VIL;
	output logic [7:0] matchH, matchL;
	output logic [7:0] maskH, maskL;
	output logic [7:0] baud_cntH, baud_cntL;
	output logic [7:0] trig_posH, trig_posL;
	
	///////////////////////////////////////////
	//            OUTPUTS TO UART            //
	///////////////////////////////////////////
	output logic [7:0] resp; 	    //data to send to host as response via UART
	output logic send_resp;  	    //initiate transmission to host via UART
	output logic clr_cmd_rdy;	    //tell UART processing has finished
	
	///////////////////////////////////////////
	//            INTERNAL SIGNALS           //
	///////////////////////////////////////////
	logic [LOG2-1:0] start_addr;	//address we start reading from. used to check if we have wrapped all the way around
	logic [7:0] response; 				//used by FSM to set value in resp
	logic start_dump;	        		//fire off a read of channel RAMs
	logic wrt_reg;               	//asserted when write reg happens
	logic inc_addr;								//used by FSM to increment the RAM raddrCHx
	logic rd_done;								//asserted when we wrap all the way around to addr we started

	///////////////////////////////////////////
	//             cmd DISSECTION            //
	///////////////////////////////////////////
	logic [1:0] op;  							//opcode from cmd[15:14]
	assign op = cmd[15:14];
	
	logic [5:0] addr; 						//address from which to read
	assign addr = cmd[13:8];

	logic [2:0] dmp_chnnl; 				//dump channel reading
	assign dmp_chnnl = cmd[10:8];

	logic [7:0] data; 						//data to be written
	assign data = cmd[7:0];

	///////////////////////////////////////////
	//   CONFIGURATION REGISTERS BEHAVIOR    //
	///////////////////////////////////////////

	//TrigCfg ff
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)
			TrigCfg <= 6'h03;
		else if (set_capture_done)
			TrigCfg[5] <= 1'b1;
		else if (wrt_reg && addr == 6'h00)
			TrigCfg <= data[5:0];
	end
			
	//CH1TrigCfg ff		
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			CH1TrigCfg <= 5'h01;
		else if (wrt_reg && addr == 6'h01)
			CH1TrigCfg <= data[4:0];
	end
			
	//CH2TrigCfg ff	
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			CH2TrigCfg <= 5'h01;
		else if (wrt_reg && addr == 6'h02)
			CH2TrigCfg <= data[4:0];
	end
			
	//CH3TrigCfg ff	
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			CH3TrigCfg <= 5'h01;
		else if (wrt_reg && addr == 6'h03)
			CH3TrigCfg <= data[4:0];
	end
			
	//CH4TrigCfg ff		
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			CH4TrigCfg <= 5'h01;
		else if (wrt_reg && addr == 6'h04)
			CH4TrigCfg <= data[4:0];
	end	

	//CH5TrigCfg ff	
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			CH5TrigCfg <= 5'h01;
		else if (wrt_reg && addr == 6'h05)
			CH5TrigCfg <= data[4:0];	
	end
			
	//decimator ff	
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)	
			decimator <= 4'h0;
		else if (wrt_reg && addr == 6'h06)
			decimator <= data[3:0];
	end
	
	//VIH ff
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			VIH <= 8'hAA;
		else if (wrt_reg && addr == 6'h07)
			VIH <= data;
	end
			
	//VIL ff
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			VIL <= 8'h55;
		else if (wrt_reg && addr == 6'h08)
			VIL <= data;
	end
			
	//matchH ff
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			matchH <= 8'h00;
		else if (wrt_reg && addr == 6'h09)
			matchH <= data;
	end
			
	//matchL ff
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			matchL <= 8'h00;
		else if (wrt_reg && addr == 6'h0A)
			matchL <= data;
	end
			
	//maskH ff
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			maskH <= 8'h00;
		else if (wrt_reg && addr == 6'h0B)
			maskH <= data;	
	end

	//maskL ff
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			maskL <= 8'h00;
		else if (wrt_reg && addr == 6'h0C)
			maskL <= data;
	end
			
	//baud_cntH ff
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			baud_cntH <= 8'h06;
		else if (wrt_reg && addr == 6'h0D)
			baud_cntH <= data;
	end
			
	//baud_cntL ff
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)		
			baud_cntL <= 8'hC8;
		else if (wrt_reg && addr == 6'h0E)
			baud_cntL <= data;
	end	
			
	//trig_posH ff
	always_ff @ (posedge clk, negedge rst_n) begin
		if(!rst_n)
			trig_posH <= 8'h00;
		else if (wrt_reg && addr == 6'h0F)
			trig_posH <= data;
	end
			
	//trig_posL ff
	always_ff @ (posedge clk, negedge rst_n) begin
		if(!rst_n)
			trig_posL <= 8'h01;	
		else if (wrt_reg && addr == 6'h10)
			trig_posL <= data;	
	end

	
	///////////////////////////////////////////
	//           INTERNAL REGISTERS          //
	///////////////////////////////////////////

	//resp ff
	/*
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) 
			resp <= 8'h00;
		else 
			resp <= response;
	end
	//*/

	assign resp = response;

	//start_addr ff
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			start_addr <= 0;
		else if(start_dump)
			//we are done when we reach this address
			start_addr <= ram_addr;
	end

	//ram_addr ff - this is the working value that is output and address that is read from each RAM module
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) 
			addr_ptr <= 0;
		else if(start_dump) 
			//start from the NEXT address. wrap if needed.
			addr_ptr <= (ram_addr == ENTRIES - 1) ? 0 : ram_addr + 1;
		else if(inc_addr) 
			//increment the addr the RAM is being read from. wrap if needed.
			addr_ptr <= (addr_ptr == ENTRIES - 1) ? 0 : addr_ptr + 1; 
	end

	//if the addr_ptr value reaches back around to where it started then we are done
	assign rd_done = ((addr_ptr == start_addr) && resp_sent);
			
	///////////////////////////////////////////
	//               MAIN FSM                //
	///////////////////////////////////////////
	//TODO: fix number of bits used when states finalized
	typedef enum reg [2:0] {IDLE, RESPOND, DUMP, DUMPING, LAST_DUMP} state_t;
	state_t state, nxt_state;
	
	//state ff
	always_ff @ (posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	end
			
	//FSM main body
	always_comb begin
		//set default values
		wrt_reg = 0;		//goes high if write cmd
		send_resp = 0;		//tell the UART to send the resp output vlaue
		response = 8'h00; 	//resp <= response 
		inc_addr = 0;		//when the UART is done sending resp then we want to get the next addr in RAM
		clr_cmd_rdy = 0;	//tell the UART we are done
		start_dump = 0;		//when this is high we want to maintain the value on ram_addr and start the dump from there
		nxt_state = IDLE;

		case(state)
			IDLE : begin
				//processing part
				if(cmd_rdy) begin
					case(op)
					
						RD: begin //read 
							case(addr)	
								6'h00: response = {2'b00, TrigCfg};							
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
								default: response = 8'hEE;
							endcase
							//TODO: do we need to wait here for the UART to be done sending?		
							nxt_state = RESPOND;	
							send_resp = 1;
						end
						
						WR: begin //write
							wrt_reg = 1;
							if(addr <= 6'h10) begin
								response = 8'hA5; 
								nxt_state = RESPOND;
							end
							else begin
								response = 8'hEE;
								nxt_state = RESPOND;
							end
							send_resp = 1;
						end	
						
						DMP: begin //dump
							nxt_state = DUMP;
							start_dump = 1;
						end
						
						default: begin //default send a nack if we dont know the cmd
							response = 8'hEE;
							send_resp = 1;
							nxt_state = RESPOND;						
						end
					endcase //endcase Op
				end //end if(cmd_rdy)
				else begin
					nxt_state = IDLE;
				end
			end //end case IDLE
			RESPOND: begin
				//response value is assumed to have been set in previous state
				//only want clr_cmd_rdy to be high for one clk cycle when resp_sent is true
				if(resp_sent) begin 
					nxt_state = IDLE;
					clr_cmd_rdy = 1;
				end
				else 
					nxt_state = RESPOND;
			end

			DUMP: begin //dump 
				case(dmp_chnnl) //assumes cmd doesnt change until we clr_cmd_rdy (cmd sent on UART)
					3'b001: response = rdataCH1;
					3'b010: response = rdataCH2;
					3'b011: response = rdataCH3;
					3'b100: response = rdataCH4;
					default: response = rdataCH5;	//default reading CH5
				endcase

				inc_addr = 1;
				send_resp = 1;
				
				if(rd_done) begin //when last bit is read, jump out of DUMP state
					nxt_state = LAST_DUMP;
				end 
				else begin
					nxt_state = DUMPING;				
				end
			end
			
			DUMPING: begin //dumping continuing here
			//the difference to DUMP is since send_resp can only assert one time
			//in the started of transmitting, but need to keep on this state
				if (resp_sent) begin
					nxt_state = DUMP;
				end 
				else begin
					nxt_state = DUMPING;//waiting and looping here until resp_sent finished
				end
			end

			LAST_DUMP: begin
				if(resp_sent) begin
					clr_cmd_rdy = 1;
					nxt_state = IDLE;
				end
				else
					nxt_state = LAST_DUMP;
			end
			
			default: begin //when none, send back neg ack 0XEE
				response = 8'hEE;
				send_resp = 1;
				nxt_state = IDLE;
				clr_cmd_rdy = 1;
			end
		endcase
	end
endmodule


