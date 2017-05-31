
`timescale 1 ns / 100 ps
module norflash_test();
	reg sys_clk;
	reg sys_rst_n;
	reg k1_n;

	reg [7:0] flash_data_wire;

	wire [7:0] flash_data;
	wire [7:0] flash_addr;
	wire flash_ce_n;
	wire flash_oe_n;
	wire flash_we_n;
	wire flash_rst_n;

	assign  flash_data = flash_data_wire;

	initial
		sys_clk = 1'b0; //初始化clock引脚为0

	always 
		#5 sys_clk = ~sys_clk; //设置clock引脚电平的翻转


	initial
		k1_n = 1'b0;

	initial
		begin
			sys_rst_n = 1'b0;
			#5 sys_rst_n = ~sys_rst_n;
		end

	initial
		begin
			#5 k1_n = ~k1_n;
			#20 k1_n = ~k1_n;
			#5 flash_data_wire = 8'b11001100;
			#20 $finish;
		end

	norflash  norflash_tester(
			.sys_clk(sys_clk),
			.sys_rst_n(sys_rst_n),
			.k1_n(k1_n),
			//flash
			.flash_data(flash_data),
			.flash_addr(flash_addr),
			.flash_ce_n(flash_ce_n),
			.flash_oe_n(flash_oe_n),
			.flash_we_n(flash_we_n),
			.flash_rst_n(flash_rst_n)
		);
endmodule