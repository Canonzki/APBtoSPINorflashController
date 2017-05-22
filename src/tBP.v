module tBP();
	
	reg [14:0]K = 14'd2;
	reg fin = 0;
	wire fout;
	reg reset = 0;
	reg fc = 0;

	always 
		#1 fc = ~fc; //设置clock引脚电平的翻转

	always 
		#8 fin = ~fin; //设置clock引脚电平的翻转

	BP bpm(.fin(fin),.fout(fout),.fc(),.reset(reset),.K(K));  

endmodule 