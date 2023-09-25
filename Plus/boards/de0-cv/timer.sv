module timer(
	input clk,
	input rst,
	output [15:0] out_time 
);

logic [15:0] timer_reg;
logic ms_clock;
logic [15:0] ms_timer ;

always_ff @( posedge clk or posedge rst ) begin : timer
	if (rst) begin
		timer_reg <= '0;
		ms_clock <= '0;
	end
	else begin
			if(timer_reg == 16'b0011_0000_1101_0100 )
				begin
				   ms_clock <=1;
				   timer_reg <=0;
				end
			else
				begin
				   ms_clock <=0;
				   timer_reg <=timer_reg + 1'b1;
				end
		end
end

always_ff @(posedge clk or posedge rst) begin
	if(rst)
		ms_timer <= '0;
	else
		if (ms_clock)
			 ms_timer <= ms_timer + 1;
end

assign out_time = ms_timer;

endmodule