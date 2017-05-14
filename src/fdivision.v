//`define N 4

module fdivision(clk_out,clk_in,rst);

output clk_out;
input clk_in;
input rst;

reg [1:0] cnt;
reg clk_out;

parameter N=8;


	always @ (posedge clk_in or negedge rst) begin
			if(!rst)
			    begin
			        cnt <= 0;
			        clk_out <= 0;
			    end
			else 
				begin
			        if(cnt==N/2-1)
			            begin 
			            	clk_out <= !clk_out; 
			            	cnt<=0; 
			            end
			        else
			          	cnt <= cnt + 1;
	    		end
	end

endmodule