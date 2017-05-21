module BP (fin,fout,fc,reset,K);  
	input  fin,fc;           //clk时钟100ns(10MHZ） 
	input  reset;     //reset高电平复位 
	input  [14:0]K;  
	output fout;           //fout是锁频锁相输出 
	wire   Kout,reset; 
	wire   [14:0]N;  

	div_N u1(
		.clkin(fc),
		.n(K),
		.reset(reset),
		.clkout(Kout)
		);         

	counter_N  u2(
		.clk(Kout), 
		.fin(fin), 
		.reset(reset), 
		.count_N(N)
		); 

	div_N u3(
		.clkin(fc),
		.n(N),
		.reset(reset),
		.fout(fout),
		.fin(fout)
		); 
endmodule