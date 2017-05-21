module xormy(a,b,y);//异或门鉴相器 
	input a,b; 
	output y; 
	reg y;  
	always @(a or b) begin        
		y=a^b; 
	end  
endmodule 