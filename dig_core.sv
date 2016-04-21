module dig_core(clk, rst_n, smpl_clk, wrt_smpl, decimator, VIH, VIL, CH1L, CH1H,
				CH2L, CH2H, CH3L, CH3H, CH4L, CH4H, CH5L, CH5H, cmd, cmd_rdy,
                clr_cmd_rdy, resp, send_resp, resp_sent, LED, we, waddr,
				raddr, wdataCH1, wdataCH2, wdataCH3, wdataCH4, wdataCH5, rdataCH1,
                rdataCH2, rdataCH3, rdataCH4, rdataCH5);
				
  	parameter ENTRIES = 384,	// defaults to 384 for simulation, use 12288 for DE-0
          	LOG2 = 9;		// Log base 2 of number of entries
			
	input clk,rst_n;			// 100MHz clock and active low asynch reset
	input wrt_smpl;			// indicates when timing is right to write a smpl
	input smpl_clk;			// goes to channel sample logic (decimated 400MHz clock)
	input CH1L,CH1H;			// signals from CH1 comparators
	input CH2L,CH2H;			// signals from CH2 comparators
	input CH3L,CH3H;			// signals from CH3 comparators
	input CH4L,CH4H;			// signals from CH4 comparators
	input CH5L,CH5H;			// signals from CH5 comparators
	input [15:0] cmd;			// command from host
	input cmd_rdy;			// indicates command from host is ready
	input resp_sent;			// indicates response has been sent to host
	input [7:0] rdataCH1;		// sample read from CH1 RAM
	input [7:0] rdataCH2;		// sample read from CH2 RAM
	input [7:0] rdataCH3;		// sample read from CH3 RAM
	input [7:0] rdataCH4;		// sample read from CH4 RAM
	input [7:0] rdataCH5;		// sample read from CH5 RAM  
	  
	output [7:0] VIH,VIL;		// sets PWM level for VIH and VIL thresholds
	output clr_cmd_rdy;		// asserted to knock down cmd_rdy after command interpretted
	output [7:0] resp;		// response to host
	output send_resp;			// asserted to initiate transmission of response to host
	output LED;				// LED output
	output we;				// write enable to all channel RAMS
	output [LOG2-1:0] waddr;	// write address to all RAMs
	output [LOG2-1:0] raddr;	// read address to all RAMs
	output [3:0] decimator;	// only every 2^decimator samples is taken
	output [7:0] wdataCH1;	// sample to write to CH1 RAM
	output [7:0] wdataCH2;	// sample to write to CH2 RAM
	output [7:0] wdataCH3;	// sample to write to CH3 RAM
	output [7:0] wdataCH4;	// sample to write to CH4 RAM
	output [7:0] wdataCH5;	// sample to write to CH5 RAM
	
	///////////////////////////////////////////////////////
	// delcare any needed internal signals as type wire //
	/////////////////////////////////////////////////////
	wire CH1Lff5, CH1Hff5, 
		CH2Lff5, CH2Hff5, 
		CH3Lff5, CH3Hff5, 
		CH4Lff5, CH4Hff5, 
		CH5Lff5, CH5Hff5; 
	wire CH1Trig, CH2Trig, CH3Trig, CH4Trig, CH5Trig;
	wire [4:0] CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg;

	///////////////////////////////////////////////////////////////
	// Instantiate the sub units that make up your digital core //
	/////////////////////////////////////////////////////////////
	sampler_reg CH1Sampl(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH1L), .CH_High(CH1H), .smpl(wdataCH1), .CHLff5(CH1Lff5), .CHHff5(CH1Hff5));
	sampler_reg CH2Sampl(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH2L), .CH_High(CH2H), .smpl(wdataCH2), .CHLff5(CH2Lff5), .CHHff5(CH2Hff5));
	sampler_reg CH3Sampl(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH3L), .CH_High(CH3H), .smpl(wdataCH3), .CHLff5(CH3Lff5), .CHHff5(CH3Hff5));
	sampler_reg CH4Sampl(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH4L), .CH_High(CH4H), .smpl(wdataCH4), .CHLff5(CH4Lff5), .CHHff5(CH4Hff5));
	sampler_reg CH5Sampl(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH5L), .CH_High(CH5H), .smpl(wdataCH5), .CHLff5(CH5Lff5), .CHHff5(CH5Hff5)); 

	channel_trigger_logic CH1Trig(.clk(clk), .set_armed(), .CHxHff5(CH1Hff5), .CHxLff5(CH1Lff5), .CHxTrigCfg(CH1TrigCfg), .ChxTrig(CH1Trig));
	channel_trigger_logic CH2Trig(.clk(clk), .set_armed(), .CHxHff5(CH2Hff5), .CHxLff5(CH2Lff5), .CHxTrigCfg(CH2TrigCfg), .ChxTrig(CH2Trig));
	channel_trigger_logic CH3Trig(.clk(clk), .set_armed(), .CHxHff5(CH3Hff5), .CHxLff5(CH3Lff5), .CHxTrigCfg(CH3TrigCfg), .ChxTrig(CH3Trig));
	channel_trigger_logic CH4Trig(.clk(clk), .set_armed(), .CHxHff5(CH4Hff5), .CHxLff5(CH4Lff5), .CHxTrigCfg(CH4TrigCfg), .ChxTrig(CH4Trig));
	channel_trigger_logic CH5Trig(.clk(clk), .set_armed(), .CHxHff5(CH5Hff5), .CHxLff5(CH5Lff5), .CHxTrigCfg(CH5TrigCfg), .ChxTrig(CH5Trig));

	trigger_logic trigLogic(.clk(clk), .rst_n(rst_n), .CH1Trig(CH1Trig), .CH2Trig(CH2Trig), .CH3Trig(CH3Trig), .CH4Trig(CH4Trig), .CH5Trig(CH5Trig), protTrig, armed, set_capture_done, triggered);
	
	//TODO: capture_cntrl needs to output the RAM ADDRESS to the cmd_cfg
	capture_cntrl capCntrl(.clk(clk), .rst_n(rst_n), .wrt_smpl(wrt_smpl), .we(we), .waddr(waddr), trig_posH, trig_posL, run, triggered, capture_done, armed, set_capture_done);  

	
	cmd_cfg cmdCfg(.clk(clk), .rst_n(rst_n), .cmd(cmd), .cmd_rdy(cmd_rdy), .resp_sent(resp_sent), set_capture_done,
				.rdataCH1(rdataCH1), .rdataCH2(rdataCH2), .rdataCH3(rdataCH3), .rdataCH4(rdataCH4), .rdataCH5(rdataCH5),
				addr_ptr, ram_addr, .decimator(decimator),
				TrigCfg, .CH1TrigCfg(CH1TrigCfg), .CH2TrigCfg(CH2TrigCfg), .CH3TrigCfg(CH3TrigCfg), .CH4TrigCfg(CH4TrigCfg), .CH5TrigCfg(CH5TrigCfg),
				VIH, VIL, matchH, matchL, maskH, maskL, baud_cntH, baud_cntL,
				trig_posH, trig_posL,
				.resp(resp), .send_resp(send_resp), .clr_cmd_rdy(clr_cmd_rdy));
endmodule  