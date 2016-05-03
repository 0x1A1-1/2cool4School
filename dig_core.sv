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
	wire CH1Trig, CH2Trig, CH3Trig, CH4Trig, CH5Trig, protTrig;
	wire [4:0] CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg;
	wire [5:0] TrigCfg;
	wire [7:0] baud_cntL, baud_cntH, maskL, maskH, matchL, matchH, trig_posL, trig_posH;
	wire set_capture_done, triggered, armed;

	///////////////////////////////////////////////////////////////
	// Instantiate the sub units that make up your digital core //
	/////////////////////////////////////////////////////////////
	sampler_reg iCH1Sampl(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH1L), .CH_High(CH1H), .smpl(wdataCH1), .CHLff5(CH1Lff5), .CHHff5(CH1Hff5));
	sampler_reg iCH2Sampl(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH2L), .CH_High(CH2H), .smpl(wdataCH2), .CHLff5(CH2Lff5), .CHHff5(CH2Hff5));
	sampler_reg iCH3Sampl(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH3L), .CH_High(CH3H), .smpl(wdataCH3), .CHLff5(CH3Lff5), .CHHff5(CH3Hff5));
	sampler_reg iCH4Sampl(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH4L), .CH_High(CH4H), .smpl(wdataCH4), .CHLff5(CH4Lff5), .CHHff5(CH4Hff5));
	sampler_reg iCH5Sampl(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH5L), .CH_High(CH5H), .smpl(wdataCH5), .CHLff5(CH5Lff5), .CHHff5(CH5Hff5)); 

	channel_trigger_logic iCH1Trig(.clk(clk), .armed(armed), .CHxHff5(CH1Hff5), .CHxLff5(CH1Lff5), .CHxTrigCfg(CH1TrigCfg), .ChxTrig(CH1Trig));
	channel_trigger_logic iCH2Trig(.clk(clk), .armed(armed), .CHxHff5(CH2Hff5), .CHxLff5(CH2Lff5), .CHxTrigCfg(CH2TrigCfg), .ChxTrig(CH2Trig));
	channel_trigger_logic iCH3Trig(.clk(clk), .armed(armed), .CHxHff5(CH3Hff5), .CHxLff5(CH3Lff5), .CHxTrigCfg(CH3TrigCfg), .ChxTrig(CH3Trig));
	channel_trigger_logic iCH4Trig(.clk(clk), .armed(armed), .CHxHff5(CH4Hff5), .CHxLff5(CH4Lff5), .CHxTrigCfg(CH4TrigCfg), .ChxTrig(CH4Trig));
	channel_trigger_logic iCH5Trig(.clk(clk), .armed(armed), .CHxHff5(CH5Hff5), .CHxLff5(CH5Lff5), .CHxTrigCfg(CH5TrigCfg), .ChxTrig(CH5Trig));

	prot_trig iprotTrig(.clk(clk), .rst_n(rst_n), .TrigCfg(TrigCfg[3:0]), .CH1L(CH1Lff5), .CH2L(CH2Lff5), .CH3L(CH3Lff5), .baud_cntH(baud_cntH), .baud_cntL(baud_cntL), .maskH(maskH), .maskL(maskL), .matchH(matchH), .matchL(matchL), .protTrig(protTrig));

	trigger_logic itrigLogic(.clk(clk), .rst_n(rst_n), .CH1Trig(CH1Trig), .CH2Trig(CH2Trig), .CH3Trig(CH3Trig), .CH4Trig(CH4Trig), .CH5Trig(CH5Trig), .protTrig(protTrig), .armed(armed), .set_capture_done(set_capture_done), .triggered(triggered));
	
	capture_cntrl icapCntrl(.clk(clk), .rst_n(rst_n), .wrt_smpl(wrt_smpl), .we(we), .waddr(waddr), .trig_posH(trig_posH), .trig_posL(trig_posL), .run(TrigCfg[4]), .triggered(triggered), .capture_done(TrigCfg[5]), .armed(armed), .set_capture_done(set_capture_done));  

	cmd_cfg icmdCfg(.clk(clk), .rst_n(rst_n), .cmd(cmd), .cmd_rdy(cmd_rdy), .resp_sent(resp_sent), .set_capture_done(set_capture_done),
				.rdataCH1(rdataCH1), .rdataCH2(rdataCH2), .rdataCH3(rdataCH3), .rdataCH4(rdataCH4), .rdataCH5(rdataCH5),
				.addr_ptr(raddr), .ram_addr(waddr), .decimator(decimator),
				.TrigCfg(TrigCfg), .CH1TrigCfg(CH1TrigCfg), .CH2TrigCfg(CH2TrigCfg), .CH3TrigCfg(CH3TrigCfg), .CH4TrigCfg(CH4TrigCfg), .CH5TrigCfg(CH5TrigCfg),
				.VIH(VIH), .VIL(VIL), .baud_cntH(baud_cntH), .baud_cntL(baud_cntL), .maskH(maskH), .maskL(maskL), .matchH(matchH), .matchL(matchL),
				.trig_posH(trig_posH), .trig_posL(trig_posL),
				.resp(resp), .send_resp(send_resp), .clr_cmd_rdy(clr_cmd_rdy));
endmodule  
