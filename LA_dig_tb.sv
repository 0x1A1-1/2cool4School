`timescale 1ns / 1ps
module LA_dig_tb();
			
//// Interconnects to DUT/support defined as type wire /////
wire clk400MHz,locked;			// PLL output signals to DUT
wire clk;						// 100MHz clock generated at this level from clk400MHz
wire VIH_PWM,VIL_PWM;			// connect to PWM outputs to monitor
wire CH1L,CH1H,CH2L,CH2H,CH3L;	// channel data inputs from AFE model
wire CH3H,CH4L,CH4H,CH5L,CH5H;	// channel data inputs from AFE model
wire RX,TX;						// interface to host
wire cmd_sent,resp_rdy;			// from master UART, monitored in test bench
wire [7:0] resp;				// from master UART, reponse received from DUT
wire tx_prot;					// UART signal for protocol triggering
wire SS_n,SCLK,MOSI;			// SPI signals for SPI protocol triggering
wire CH1L_mux,CH1H_mux;         // output of muxing logic for CH1 to enable testing of protocol triggering
wire CH2L_mux,CH2H_mux;			// output of muxing logic for CH2 to enable testing of protocol triggering
wire CH3L_mux,CH3H_mux;			// output of muxing logic for CH3 to enable testing of protocol triggering

////// Stimulus is declared as type reg ///////
reg REF_CLK, RST_n;
reg [15:0] host_cmd;			// command host is sending to DUT
reg send_cmd;					// asserted to initiate sending of command
reg clr_resp_rdy;				// asserted to knock down resp_rdy
reg [1:0] clk_div;				// counter used to derive 100MHz clk from clk400MHz
reg strt_tx;					// kick off unit used for protocol triggering

/////////////////////////////////////////////////////////////
// Channel Dumps can be written to file to aid in testing //
///////////////////////////////////////////////////////////
// setup file pointers here if going to do that
int fptr1, fptr2, fptr3, fptr4, fptr5;


///////////////////////////
// Define command bytes //
/////////////////////////
// May or may not want to make some localparams to represent command bytes to LA core

/////////////////////////////////
localparam UART_triggering = 1'b1;	// set to true if testing UART based triggering
localparam SPI_triggering = 1'b0;	// set to true if testing SPI based triggering


///// Instantiate Analog Front End model (provides stimulus to channels) ///////
AFE iAFE(.smpl_clk(clk400MHz),.VIH_PWM(VIH_PWM),.VIL_PWM(VIL_PWM),
         .CH1L(CH1L),.CH1H(CH1H),.CH2L(CH2L),.CH2H(CH2H),.CH3L(CH3L),
         .CH3H(CH3H),.CH4L(CH4L),.CH4H(CH4H),.CH5L(CH5L),.CH5H(CH5H));
		 
//// Mux for muxing in protocol triggering for CH1 /////
assign {CH1H_mux,CH1L_mux} = (UART_triggering) ? {2{tx_prot}} :		// assign to output of UART_tx used to test UART triggering
                             (SPI_triggering) ? {2{SS_n}}: 			// assign to output of SPI SS_n if SPI triggering
				             {CH1H,CH1L};

//// Mux for muxing in protocol triggering for CH2 /////
assign {CH2H_mux,CH2L_mux} = (SPI_triggering) ? {2{SCLK}}: 			// assign to output of SPI SCLK if SPI triggering
				             {CH2H,CH2L};	

//// Mux for muxing in protocol triggering for CH3 /////
assign {CH3H_mux,CH3L_mux} = (SPI_triggering) ? {2{MOSI}}: 			// assign to output of SPI MOSI if SPI triggering
				             {CH3H,CH3L};					  
	 
////// Instantiate DUT ////////
LA_dig iDUT(.clk400MHz(clk400MHz),.RST_n(RST_n),.locked(locked),
            .VIH_PWM(VIH_PWM),.VIL_PWM(VIL_PWM),.CH1L(CH1L_mux),.CH1H(CH1H_mux),
			.CH2L(CH2L_mux),.CH2H(CH2H_mux),.CH3L(CH3L_mux),.CH3H(CH3H_mux),.CH4L(CH4L),
			.CH4H(CH4H),.CH5L(CH5L),.CH5H(CH5H),.RX(RX),.TX(TX), .LED());

///// Instantiate PLL to provide 400MHz clk from 50MHz ///////
pll8x iPLL(.ref_clk(REF_CLK),.RST_n(RST_n),.out_clk(clk400MHz),.locked(locked));

///// It is useful to have a 100MHz clock at this level similar //////
///// to main system clock (clk).  So we will create one        //////
always @(posedge clk400MHz, negedge locked)
  if (~locked)
    clk_div <= 2'b00;
  else
    clk_div <= clk_div+1;
assign clk = clk_div[1];

//// Instantiate Master UART (mimics host commands) //////
CommMaster iMSTR(.clk(clk), .rst_n(RST_n), .RX(TX), .TX(RX),
                     .cmd(host_cmd), .snd_cmd(send_cmd),
					 .cmd_cmplt(cmd_sent), .rdy(resp_rdy),
					 .rx_data(resp), .clr_rdy(clr_resp_rdy));
					 
////////////////////////////////////////////////////////////////
// Instantiate transmitter as source for protocol triggering //
//////////////////////////////////////////////////////////////
UART_tx iTX(.clk(clk), .rst_n(RST_n), .TX(tx_prot), .trmt(strt_tx),
        .tx_data(8'h96), .tx_done());
					 
////////////////////////////////////////////////////////////////////
// Instantiate SPI transmitter as source for protocol triggering //
//////////////////////////////////////////////////////////////////
SPI_mstr iSPI(.clk(clk),.rst_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.wrt(strt_tx),.done(done),
              .data_out(16'h6600),.MOSI(MOSI),.pos_edge(1'b0),.width8(1'b1));
initial begin
  //   put your testing code here.
  
    // openning dump file to write
  fptr1 = $fopen("CH1dmp.txt","w");
  fptr2 = $fopen("CH2dmp.txt","w");
  fptr3 = $fopen("CH3dmp.txt","w");
  fptr4 = $fopen("CH4dmp.txt","w");
  fptr5 = $fopen("CH5dmp.txt","w");
  
  //initialize design
  strt_tx = 0;
  initialize;
 
  //first test: writing to trig_cfg and read from trig_cfg
  sndcmd({WR,TRIG_CFG, 8'b001_0010});
  chkresp(8'hA5);
  repeat(10) @ (negedge clk);
  sndcmd({RD,TRIG_CFG, 8'h00});
  chkresp(8'b0001_0010);
  
  //wrong cmd test
  sndcmd({2'b11,VIH, 8'h46});
  chkresp(8'hEE);


  //change trig_pos
  sndcmd({WR,TRIG_POS_H,8'h06});
  chkresp(8'hA5);
  sndcmd({WR,TRIG_POS_L,8'h55});
  chkresp(8'hA5);

  //change CHxTrigCfg
  sndcmd({WR,CH1TRIG_CFG,8'b0000_1000});
  chkresp(8'hA5);
  sndcmd({WR,CH1TRIG_CFG,8'b0001_0000});
  chkresp(8'hA5);
  
  //dump test
  PollCapDone;
  
  sndcmd({DUMP,DPCH1, 8'h00});
  dump(DPCH1);
  sndcmd({DUMP,DPCH2, 8'h00});
  dump(DPCH2);
  sndcmd({DUMP,DPCH3, 8'h00});
  dump(DPCH3);
  sndcmd({DUMP,DPCH4, 8'h00});
  dump(DPCH4);
  sndcmd({DUMP,DPCH5, 8'h00});
  dump(DPCH5);
  
  $fclose(fptr1);
  $fclose(fptr2); 
  $fclose(fptr3);
  $fclose(fptr4);
  $fclose(fptr5);     
  $finish;
  
end

always
  #100 REF_CLK = ~REF_CLK;

///// Perhaps put some basic tasks in a separate file to keep your test bench less cluttered /////
`include "tb_tasks.v"

endmodule	
