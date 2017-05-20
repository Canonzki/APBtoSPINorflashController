//`define N 4

module fdivision(clk_out,clk_in,rst);

output clk_out;
input clk_in;
input rst;

reg [1:0] cnt = 2'b00;
reg clk_out;

parameter N = 4;

always @ (posedge clk_in or negedge rst) begin
	if(!rst)
	    begin
	        cnt <= 0;
	        clk_out <= 0;
	        $display("%b,%b",cnt,clk_out);
	        $display("branch 1");
	    end
	else 
		begin
	        if(cnt==N/2-1)
	            begin 
	            	clk_out <= !clk_out; 
	            	cnt<=0; 
	            	$display("%b,%b",cnt,clk_out);
	        		$display("branch 2");
	            end
	        else
	          	cnt <= cnt + 1;
	          	$display("%b,%b",cnt,clk_out);
	        	$display("branch 3");
	    end
end

endmodule