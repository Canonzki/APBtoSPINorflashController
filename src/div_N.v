module div_N  (clkin,n,reset,clkout);   //N分频模块   
	input clkin,reset;   
	input [14:0] n;   
	output clkout;   
	reg clkout;      
	integer count;     

	always @(posedge clkin)       
		if(reset) begin            
			clkout=0;            
			count=0;
		end       
		else begin            
			if(count>=(n/2)-1) begin  
				clkout<=~clkout;count<=0;
			end            
			else                
				count<=count+1;           
		end 

endmodule