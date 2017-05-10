`timescale 1 ns / 100 ps

module controller_test()

	reg p_clk;
	reg p_reset_n;
	reg [`APBBITWIDE-1:0] p_addr;
	reg p_write;
	reg p_sel_x;
	reg p_enable;
	wire [`APBBITWIDE-1:0] p_data;

	reg [`SPIBITWIDE-1:0] s_mosi;
	wire [`SPIBITWIDE-1:0] s_miso;
	wire s_clk;
	wire s_css;

	initial
		p_clk = 1'b0; //初始化clock引脚为0

	always 
		#8 p_clk = ~p_clk; //设置clock引脚电平的翻转


	controller norflash_contorller(
									.p_clk(p_clk),   
									.p_reset_n(p_reset_n),
									.p_addr(p_addr),  
									.p_write(p_write), 
									.p_sel_x(p_sel_x), 
									.p_enable(p_enable),
									.p_data(p_data),  
									//spi引脚
									.s_mosi(s_mosi),  
									.s_miso(s_miso),  
									.s_clk(s_clk),   
									.s_css(s_css),	
									);


endmodule