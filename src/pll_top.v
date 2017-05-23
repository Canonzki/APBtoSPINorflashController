module pll_top (
			fin,
			fout,
			se,4
			clk,
			reset,
			enable,
			Kmode,
			pulse,
			n
			); 
			input  fin,clk;           //clk时钟100ns(10MHZ）  
			input  reset,enable;     //reset高电平复位，enable高电平有效 
			input  [2:0]Kmode;      //滤波计数器的计数模值设定 
			output fout;           //fout是锁频锁相输出 
			output pulse;         //pulse是倍频输出 
			input  [14:0]n;      //倍频系数设定 
			output se;          //锁相信号 
			wire   idout,reset,ca,bo,dout; 
			wire   [14:0]N;
			wire   [14:0]M;  

			xormy u1(
				.a(fin),
				.b(fout),
				.y(se)
				); 

			KCounter u2(
				.Kclock(clk),
				.reset(reset),
				.dnup(se),
				.enable(enable),
				.Kmode(Kmode),
				.carry(ca),
				.borrow(bo)
				);

			IDCounter u3(
				.IDclock(clk),
				.reset(reset),
				.inc(ca),.dec(bo),
				.IDout(idout)
				); 
			counter_N u4(
				.clk(clk), 
				.fin(fin), 
				.reset(reset), 
				.count_N(N)
				); 

			div_N u5(
				.clkin(idout),
				.n(N),
				.reset(reset),
				.clkout(fout)
				);

			div_N u6(
				.clkin(clk),
				.n(n),
				.reset(reset),
				.clkout(dout)
				);

			counter_N u7(
				.clk(dout), 
				.fin(fout), 
				.reset(reset), 
				.count_N(M)
				);

			div_N u8(
				.clkin(clk),
				.n(M),
				.reset(reset),
				.clkout(pulse)
				);

endmodule