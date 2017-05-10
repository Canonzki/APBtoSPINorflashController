`timescale 1 ns / 100 ps
`define APBBITWIDE 32
`define SPIBITWIDE 8



module controller(

		//amba引脚
		p_clk,     //时钟
		p_reset_n, //复位,低位有效
		p_addr,    //地址线最高32bit
		p_write,   //写信号高位表示要写
		p_sel_x,   //片选信号，默认置1，表示永久选中该设备
		p_enable,  //使能信号
		p_data,    //数据线，最高32bit，该引脚为inout类型，读和写的数据都要通过它


		//spi引脚
		s_mosi,     //主设备输入，从设备输出，在这里controller是主设备，所以是个输入的引脚
		s_miso,     //主设备输出，从设备输入，在这里controller是从设备，所以是个out类型的引脚
		s_clk,      //时钟位，由主设备产生，所以是个out类型的引脚
		s_css,		//从设备使能信号，同样由主设备输出，是个out类型的引脚
	);

	//amba引脚
	input p_clk;
	input p_reset_n;
	input [`APBBITWIDE-1:0] p_addr;
	input p_write;
	input p_sel_x;
	input p_enable;

	inout [`APBBITWIDE-1:0] p_data;

	//spi引脚
	input [`SPIBITWIDE-1:0] s_mosi;
	output [`SPIBITWIDE-1:0] s_miso;
	output s_clk;
	output s_css;

	reg [`APBBITWIDE-1:0] p_addr;
	//reg [`APBBITWIDE-1:0] p_data;

	reg s_css;

	always @(*) begin
		if (p_reset_n == 1'b0) begin
			assign s_css = ~p_reset_n;
		end
	end


	fdivision divider(.clk_out(s_clk),.clk_in(p_clk),.rst());


endmodule