module pwm8(clk, rst_n, duty, PWM_sig);

input clk, rst_n;
input [7:0] duty;
output reg PWM_sig;

reg [7:0] counter;

always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		counter <= 0;
	else
		counter <= counter + 1;

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		PWM_sig <= 0;
	else if(&counter)
		PWM_sig <= 1;
	else if(counter == duty)
		PWM_sig <= 0;
end


endmodule
