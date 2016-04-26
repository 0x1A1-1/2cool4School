`timescale 1ns / 1ps
module channel_sample_tb();

logic ref_clk, clk, smpl_clk, clk400MHz; 
logic RST_n, rst_n;     

logic VIH_PWM, VIL_PWM;
logic locked;
logic [3:0] decimator; 

logic [7:0] VIH, VIL, smpl1, smpl2, smpl3, smpl4, smpl5;
logic CH1Hff5, CH1Lff5, CH2Hff5, CH2Lff5, CH3Hff5, CH3Lff5, CH4Hff5, CH4Lff5, CH5Hff5, CH5Lff5;
logic CH1H, CH1L, CH2H, CH2L, CH3H, CH3L, CH4H, CH4L, CH5H, CH5L;
logic wrt_smpl;

////// instantiate pll8x module////////
pll8x ipll8x(.ref_clk(ref_clk), .RST_n(RST_n), .out_clk(clk400MHz), .locked(locked));

////// instantiate clk_rst_smpl module////////
clk_rst_smpl iclk_rst_smpl(.clk400MHz(clk400MHz), .RST_n(RST_n), .locked(locked), .decimator(decimator), .clk(clk), .smpl_clk(smpl_clk), .rst_n(rst_n), .wrt_smpl(wrt_smpl));

////// instantiate dual_PWM module////////
dual_PWM idPWM(.clk(clk), .rst_n(rst_n), .VIL(VIL), .VIL_PWM(VIL_PWM), .VIH(VIH), .VIH_PWM(VIH_PWM));

////// instantiate AFE module////////
AFE iAFE(.smpl_clk(smpl_clk), .VIH_PWM(VIH_PWM), .VIL_PWM(VIL_PWM), .CH1L(CH1L), .CH1H(CH1H), .CH2L(CH2L), .CH2H(CH2H), .CH3L(CH3L), .CH3H(CH3H), .
           CH4L(CH4L), .CH4H(CH4H), .CH5L(CH5L), .CH5H(CH5H));

////// instantiate 5 channel_sample modules////////		   
sampler_reg ch1(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH1L), .CH_High(CH1H), .smpl(smpl1), .CHLff5(CH1Lff5), .CHHff5(CH1Hff5));	
sampler_reg ch2(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH2L), .CH_High(CH2H), .smpl(smpl2), .CHLff5(CH2Lff5), .CHHff5(CH2Hff5));
sampler_reg ch3(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH3L), .CH_High(CH3H), .smpl(smpl3), .CHLff5(CH3Lff5), .CHHff5(CH3Hff5));
sampler_reg ch4(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH4L), .CH_High(CH4H), .smpl(smpl4), .CHLff5(CH4Lff5), .CHHff5(CH4Hff5));
sampler_reg ch5(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH5L), .CH_High(CH5H), .smpl(smpl5), .CHLff5(CH5Lff5), .CHHff5(CH5Hff5));
	
initial begin
	RST_n = 0;
	#1
	RST_n = 1;
	ref_clk = 1;
	VIH = 8'haa;
	VIL = 8'h55;
	decimator = 2;   // set sample numbers to 4
end

always #10 ref_clk=~ref_clk; // simulate 50 MHz reference clk

/* If we need the Trig Yet ?	
channel_trigger_logic ch1Trig(.clk(clk), .set_armed(set_armed), .CHxHff5(CH1Hff5), .CHxLff5(CH1Lff5), .CHxTrigCfg(CH1TrigCfg), .ChxTrig(Ch1Trig));
channel_trigger_logic ch2Trig(.clk(clk), .set_armed(set_armed), .CHxHff5(CH2Hff5), .CHxLff5(CH2Lff5), .CHxTrigCfg(CH2TrigCfg), .ChxTrig(Ch2Trig));
channel_trigger_logic ch3Trig(.clk(clk), .set_armed(set_armed), .CHxHff5(CH3Hff5), .CHxLff5(CH3Lff5), .CHxTrigCfg(CH3TrigCfg), .ChxTrig(Ch3Trig));
channel_trigger_logic ch4Trig(.clk(clk), .set_armed(set_armed), .CHxHff5(CH4Hff5), .CHxLff5(CH4Lff5), .CHxTrigCfg(CH4TrigCfg), .ChxTrig(Ch4Trig));
channel_trigger_logic ch5Trig(.clk(clk), .set_armed(set_armed), .CHxHff5(CH5Hff5), .CHxLff5(CH5Lff5), .CHxTrigCfg(CH5TrigCfg), .ChxTrig(Ch5Trig));
*/

endmodule
