module channel_sample_tb();

AFE iAFE(.smpl_clk(smpl_clk), .VIH_PWM(VIH_PWM), .VIL_PWM(VIL_PWM), .CH1L(CH1L), .CH1H(CH1H), .CH2L(CH2L), .CH2H(CH2H), .CH3L(CH3L), .CH3H(CH3H), .
           CH4L(CH4L), .CH4H(CH4H), .CH5L(CH5L), .CH5H(CH5H));
		   
clk_rst_smpl iclk_rst_smpl(.clk400MHz(clk400MHz), .RST_n(RST_n), .locked(locked), .decimator(decimator), .clk(clk), .smpl_clk(smpl_clk), .rst_n(rst_n), .wrt_smpl(wrt_smpl));

pll8x ipll8x(.ref_clk(ref_clk), .RST_n(RST_n), .out_clk(clk400MHz), .locked(locked));

sampler_reg ch1(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH1L), .CH_High(CH1H), .smpl(smpl1), .CHLff5(CH1Lff5), .CHHff5(CH1Hff5));	
sampler_reg ch2(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH2L), .CH_High(CH2H), .smpl(smpl2), .CHLff5(CH2Lff5), .CHHff5(CH2Hff5));
sampler_reg ch3(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH3L), .CH_High(CH3H), .smpl(smpl3), .CHLff5(CH3Lff5), .CHHff5(CH3Hff5));
sampler_reg ch4(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH4L), .CH_High(CH4H), .smpl(smpl4), .CHLff5(CH4Lff5), .CHHff5(CH4Hff5));
sampler_reg ch5(.clk(clk), .smpl_clk(smpl_clk), .CH_Low(CH5L), .CH_High(CH5H), .smpl(smpl5), .CHLff5(CH5Lff5), .CHHff5(CH5Hff5));
	
/* If we need the Trig Yet ?	
channel_trigger_logic ch1Trig(.clk(clk), .set_armed(set_armed), .CHxHff5(CH1Hff5), .CHxLff5(CH1Lff5), .CHxTrigCfg(CH1TrigCfg), .ChxTrig(Ch1Trig));
channel_trigger_logic ch2Trig(.clk(clk), .set_armed(set_armed), .CHxHff5(CH2Hff5), .CHxLff5(CH2Lff5), .CHxTrigCfg(CH2TrigCfg), .ChxTrig(Ch2Trig));
channel_trigger_logic ch3Trig(.clk(clk), .set_armed(set_armed), .CHxHff5(CH3Hff5), .CHxLff5(CH3Lff5), .CHxTrigCfg(CH3TrigCfg), .ChxTrig(Ch3Trig));
channel_trigger_logic ch4Trig(.clk(clk), .set_armed(set_armed), .CHxHff5(CH4Hff5), .CHxLff5(CH4Lff5), .CHxTrigCfg(CH4TrigCfg), .ChxTrig(Ch4Trig));
channel_trigger_logic ch5Trig(.clk(clk), .set_armed(set_armed), .CHxHff5(CH5Hff5), .CHxLff5(CH5Lff5), .CHxTrigCfg(CH5TrigCfg), .ChxTrig(Ch5Trig));
*/

endmodule
