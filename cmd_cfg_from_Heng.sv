module cmd_cfg(clk, rst_n, cmd, cmd_rdy, resp_sent, rd_done, set_capture_done, rdataCH1,rdataCH2, rdataCH3, rdataCH4,
		rdataCH5, ram_addr, TrigCfg, CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg, decimator, VIH,
		VIL, matchH, matchL, maskH, maskL, baud_cntH, baud_cntL, trig_posH, trig_posL, resp, send_resp, clr_cmd_rdy,
		strt_rd); //put list in here 
2 
 
3 	parameter ENTRIES = 384, LOG2 = 9;	 
4 	 
5 	localparam RD = 2'b00; //RD indicates read Opcode
6 	localparam WR = 2'b01; //WR indicates write Opcode
7 	localparam DMP = 2'b10; // DMP indicates dump Opcode
8 	 
9 	input clk, rst_n; //system clk and rst_n 
10 	input [15:0] cmd; //16 bits cmd from UART.The upper 2-bits [15:14] encodes the opcode 
11 	input cmd_rdy; //cmd is ready for use 
12 	input resp_sent; // asserted when transmission of resp to host is finished 
13 	input rd_done; // asserted when last bite of sample data has been read 
14 	input set_capture_done; // sets capture done bit 
15 	input [7:0] rdataCH1, rdataCH2, rdataCH3, rdataCH4, rdataCH5;//Read Data From RAM 
16 
 
17 	//ram address is same across all 5 queues 
18 	//output from capture_cntrl block 
19 	input [LOG2-1:0] ram_addr; //last valid addr written to ram. read from this value + 1 to ram_addr (wrap around @ ENTRIES) 
20 	 
21 	//register set 
22 	output logic [5:0] TrigCfg; 
23 	output logic [4:0] CH1TrigCfg, CH2TrigCfg, CH3TrigCfg, CH4TrigCfg, CH5TrigCfg; 
24 	output logic [3:0] decimator; 
25 	output logic [7:0] VIH, VIL; 
26 	output logic [7:0] matchH, matchL; 
27 	output logic [7:0] maskH, maskL; 
28 	output logic [7:0] baud_cntH, baud_cntL; 
29 	output logic [LOG2-1:0] trig_posH, trig_posL; 
30 	 
31 	output logic [7:0] resp; //data send to host as response 
32 	output logic send_resp; //initiate transmission to host 
33 	output logic clr_cmd_rdy; // used when processing finished 
34 	output logic strt_rd; //fire off a read of channel RAMs 
35 
 
36 	logic wrt_reg;//asserted when write reg happens 
37 	logic [7:0] data; //data to be written 
38 	logic [2:0] dmp_chnnl; //dump channel reading 
39 	logic [1:0] op; //opcode from cmd[15:14] 
40 	logic [5:0] addr; //address from which to read 
41 	 
42 	assign data = cmd[7:0]; 
43 	assign dmp_chnnl = cmd[10:8]; 
44 	assign op = cmd[15:14]; 
45 	assign addr = cmd[13:8]; 
46 	 
47 	//TrigCfg ff 
48 	always_ff @ (posedge clk, negedge rst_n) begin 
49 		if (!rst_n) 
50 			TrigCfg <= 6'h03; 
51 		else if (wrt_reg && wrt_add == 6'h00) 
52 			TrigCfg <= data[5:0]; 
		else if (set_capture_done)
			TrigCfg[5] <= 1'b1;
53 	end 

	
54 			 
55 	//CH1TrigCfg ff		 
56 	always_ff @ (posedge clk, negedge rst_n) begin 
57 		if (!rst_n)		 
58 			CH1TrigCfg <= 5'h01; 
59 		else if (wrt_reg && wrt_add == 6'h01) 
60 			CH1TrigCfg <= data[4:0]; 
61 	end 
62 			 
63 	//CH2TrigCfg ff	 
64 	always_ff @ (posedge clk, negedge rst_n) begin 
65 		if (!rst_n)		 
66 			CH2TrigCfg <= 5'h01; 
67 		else if (wrt_reg && wrt_add == 6'h02) 
68 			CH2TrigCfg <= data[4:0]; 
69 	end 
70 			 
71 	//CH3TrigCfg ff	 
72 	always_ff @ (posedge clk, negedge rst_n) begin 
73 		if (!rst_n)		 
74 			CH3TrigCfg <= 5'h01; 
75 		else if (wrt_reg && wrt_add == 6'h03) 
76 			CH3TrigCfg <= data[4:0]; 
77 	end 
78 			 
79 	//CH4TrigCfg ff		 
80 	always_ff @ (posedge clk, negedge rst_n) begin 
81 		if (!rst_n)		 
82 			CH4TrigCfg <= 5'h01; 
83 		else if (wrt_reg && wrt_add == 6'h04) 
84 			CH4TrigCfg <= data[4:0]; 
85 	end	 
86 
 
87 	//CH5TrigCfg ff	 
88 	always_ff @ (posedge clk, negedge rst_n) begin 
89 		if (!rst_n)		 
90 			CH5TrigCfg <= 5'h01; 
91 		else if (wrt_reg && wrt_add == 6'h05) 
92 			CH5TrigCfg <= data[4:0];	 
93 	end 
94 			 
95 	//decimator ff	 
96 	always_ff @ (posedge clk, negedge rst_n) begin 
97 		if (!rst_n)	 
98 			decimator <= 4'h0; 
99 		else if (wrt_reg && wrt_add == 6'h06) 
100 			decimator <= data[3:0]; 
101 	end 
102 	 
103 	//VIH ff 
104 	always_ff @ (posedge clk, negedge rst_n) begin 
105 		if (!rst_n)		 
106 			VIH <= 8'hAA; 
107 		else if (wrt_reg && wrt_add == 6'h07) 
108 			VIH <= data; 
109 	end 
110 			 
111 	//VIL ff 
112 	always_ff @ (posedge clk, negedge rst_n) begin 
113 		if (!rst_n)		 
114 			VIL <= 8'h55; 
115 		else if (wrt_reg && wrt_add == 6'h08) 
116 			VIL <= data; 
117 	end 
118 			 
119 	//matchH ff 
120 	always_ff @ (posedge clk, negedge rst_n) begin 
121 		if (!rst_n)		 
122 			matchH <= 8'h00; 
123 		else if (wrt_reg && wrt_add == 6'h09) 
124 			matchH <= data; 
125 	end 
126 			 
127 	//matchL ff 
128 	always_ff @ (posedge clk, negedge rst_n) begin 
129 		if (!rst_n)		 
130 			matchL <= 8'h00; 
131 		else if (wrt_reg && wrt_add == 6'h0A) 
132 			matchL <= data; 
133 	end 
134 			 
135 	//maskH ff 
136 	always_ff @ (posedge clk, negedge rst_n) begin 
137 		if (!rst_n)		 
138 			maskH <= 8'h00; 
139 		else if (wrt_reg && wrt_add == 6'h0B) 
140 			maskH <= data;	 
141 	end 
142 
 
143 	//maskL ff 
144 	always_ff @ (posedge clk, negedge rst_n) begin 
145 		if (!rst_n)		 
146 			maskL <= 8'h00; 
147 		else if (wrt_reg && wrt_add == 6'h0C) 
148 			maskL <= data; 
149 	end 
150 			 
151 	//baud_cntH ff 
152 	always_ff @ (posedge clk, negedge rst_n) begin 
153 		if (!rst_n)		 
154 			baud_cntH <= 8'h06; 
155 		else if (wrt_reg && wrt_add == 6'h0D) 
156 			baud_cntH <= data; 
157 	end 
158 			 
159 	//baud_cntL ff 
160 	always_ff @ (posedge clk, negedge rst_n) begin 
161 		if (!rst_n)		 
162 			baud_cntL <= 8'hC8; 
163 		else if (wrt_reg && wrt_add == 6'h0E) 
164 			baud_cntL <= data; 
165 	end	 
166 			 
167 	//trig_posH ff 
168 	always_ff @ (posedge clk, negedge rst_n) begin 
169 		if(!rst_n) 
170 			trig_posH <= 8'h00; 
171 		else if (wrt_reg && wrt_add == 6'h0F) 
172 			trig_posH <= data; 
173 	end 
174 			 
175 	//trig_posL ff 
176 	always_ff @ (posedge clk, negedge rst_n) begin 
177 		if(!rst_n) 
178 			trig_posL <= 8'h01;	 
179 		else if (wrt_reg && wrt_add == 6'h10) 
180 			trig_posL <= data;	 
181 	end 
182 
 
183 	//resp ff 
184 	always_ff @(posedge clk, negedge rst_n) begin 
185 		if(!rst_n) resp <= 8'h00; 
186 		else resp <= response; 
187 	end  
188 			 
189 			 
190 	//main FSM		 
191 	typedef enum reg [2:0] {IDLE, RESPOND, DUMP, DUMPING} state_t; 
192 	state_t state, nxt_state; 
193 	 
194 	always_ff @ (posedge clk, negedge rst_n) begin 
195 		if(!rst_n) 
196 			state <= IDLE; 
197 		else 
198 			state <= nxt_state; 
199 	end 
200 			 
201 	//FSM main body 
202 	always_comb begin 
203 		//set default values 
204 		wrt_reg = 0; 
205 		send_resp = 0; 
206 		response = 8'h00; //should this default to 00? 
207 		nxt_state = IDLE; 
208 		clr_cmd_rdy = 0; 
209 		strt_rd = 0; 
210 		 
211 		case(state) 
212 			IDLE :  
213 				//processing part 
214 				if(cmd_rdy) begin 
215 					case(op) 
216 					 
217 						RD: begin //Read  
218 							case(addr):								 
219 								6'h01: response = {3'b000, CH1TrigCfg}; 
220 								6'h02: response = {3'b000, CH2TrigCfg}; 
221 								6'h03: response = {3'b000, CH3TrigCfg}; 
222 								6'h04: response = {3'b000, CH4TrigCfg}; 
223 								6'h05: response = {3'b000, CH5TrigCfg};		 
224 								6'h06: response = {4'b000, decimator}; 
225 								6'h07: response = VIH; 
226 								6'h08: response = VIL; 
227 								6'h09: response = matchH; 
228 								6'h0A: response = matchL; 
229 								6'h0B: response = maskH;	 
230 								6'h0C: response = maskL; 
231 								6'h0D: response = baud_cntH; 
232 								6'h0E: response = baud_cntL; 
233 								6'h0F: response = trig_posH;  
234 								6'h10: response = trig_posL; 
235 								default: response = {2'b00, TrigCfg}; 
236 							endcase		 
237 							nxt_state = IDLE;	 
238 							clr_cmd_rdy = 1; 
239 							send_resp = 1; 
240 						end 
241 						 
242 						WR: begin //write 
243 							wrt_reg = 1; 
244 							 
245 							//may need to send ack one clock period later 
246 							response = 8'hA5; 
247 							send_resp = 1; 
248 							nxt_state = RESPOND; 
249 						end	 
250 						 
251 						DMP: begin //dump 
252 							nxt_state = DUMP; 
253 							strt_rd = 1; 
254 						end 
255 						 
256 						default: begin //reserved for future use 
257 							response = 8'hEE; 
258 							send_resp = 1; 
259 							nxt_state = RESPOND;						 
260 						end 
261 			 
262 					endcase //endcase Op 
263 				end  
264 				else 
265 					nxt_state = IDLE; 
266 				 
267 			RESPOND: begin 
268 				if(resp_sent) begin  
269 					nxt_state = IDLE; 
270 					clr_cmd_rdy = 1; 
271 				end 
272 				else  
273 					nxt_state = RESPOND; 
274 			end 
275 
 
276 			DUMP: begin //dump state 
277 				case(dmp_chnnl) 
278 					3'b001: response = rdataCH1; 
279 					3'b010: response = rdataCH2; 
280 					3'b011: response = rdataCH3; 
281 					3'b100: response = rdataCH4; 
282 					default: response = rdataCH5;//default reading CH5 
283 				endcase 
284 				 
285 				if(rd_done) begin // when last bit is read, jump out of DUMP state 
286 					clr_cmd_rdy = 1; 
287 					nxt_state = IDLE; 
288 				end  
289 				else begin 
290 					nxt_state = DUMPING; 
291 					send_resp = 1; 
292 				end 
293 			end 
294 			 
295 			DUMPING: begin //dumping continuing here 
296 			//the difference to DUMP is since send_resp can only assert one time 
297 			//in the started of transmitting, but need to keep on this state 
298 				if (resp_sent) begin 
299 					nxt_state = DUMP; 
300 				end else begin 
301 					nxt_state = DUMPING;//waiting and looping here until resp_sent finished 
302 				end 
303 			end 
304 			 
305 			default: begin //when none, send back neg ack 0XEE 
306 				resp = 2'hEE; 
307 				send_resp = 1; 
308 				nxt_state = IDLE; 
309 				clr_cmd_rdy = 1; 
310 			end 
311 
 
312 			 
313 endmodule 
