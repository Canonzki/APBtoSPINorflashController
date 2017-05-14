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
		p_enable,  //使能信号高电平有效
		p_data,    //数据线，最高32bit，该引脚为inout类型，读和写的数据都要通过它


		//spi引脚
		s_miso,     //主设备输入，从设备输出，在这里controller是从设备，所以是个out类型的引脚
		s_mosi,     //主设备输出，从设备输入，在这里controller是主设备，所以是个输入的引脚
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
	input [`SPIBITWIDE-1:0] s_miso;
	output [`SPIBITWIDE-1:0] s_mosi;
	
	output s_clk;
	output s_css;

	wire p_clk;
	wire s_clk;

	reg [`APBBITWIDE-1:0] p_addr;
	reg [`APBBITWIDE-1:0] p_data;
	
	reg s_css;

	//状态寄存器两颗，00表示默认状态(idel)，01表示启动状态(setup)，10表示使能状态(enable)，11保留；
	reg [1:0]status;
	reg [`APBBITWIDE-1:0] fdcount;

	//数据双工通信控制
	wire [`APBBITWIDE-1:0]p_data;
	reg [`APBBITWIDE-1:0]p_data_in;
	reg [`APBBITWIDE-1:0]p_data_out;
	reg p_write;
	always @(*) begin
		if (p_write==1'b1) begin
			if (status==2'b10) begin
				//当写信号为低时，将输出缓冲区中的数据输出
				assign [`APBBITWIDE-1:0]p_data = (p_write==1'b0)?p_data_out:32'bz;
				//当写信号为高时，将输入数据放入写数据缓冲区
				p_data_in = p_data;	
			end
		end
	end

	//重置逻辑
	always @(*) begin
		if (p_reset_n == 1'b0) begin
			assign s_css <= ~p_reset_n;
			status <= 2'b00;
			fdcount = 8'b00000000;
		end
		else begin
			assign s_css <= ~p_enable;
		end
	end

	//状态控制逻辑
	always @(posedge p_clk) begin
		fdcount = 8'b00000000;
		if(p_reset_n==1'b1) begin
			//当偏选信号为0时将状态置为idel
			if (p_sel_x==1'b0) begin
				status = 2'b00;
			end
			else if (p_sel_x==1'b1) begin
				//当偏选信号为1时且使能端为0时进入setup状态
				if (p_enable==1'b0) begin
					status = 2'b01
				end
				else begin
					//当偏选信号为1，且使能端为1时进入enable装爱
					status = 2'b10;
				end
			end
		end
	end

	//计数器，计算分频器分频之后当权处于子周期中的第fdcount周期
	always @(posedge s_clk) begin
		fdcount = fdcount + 1;
	end

	//当传输开始时
	always @(posedge s_clk) begin
		if (status==2'b01) begin
			case(p_write)
				1'b0:begin
					case(fdcount)
						1:begin
							s_mosi<=8'b00000001;
						end
						2:begin
							s_mosi<=p_addr[31:24];
						end
						3:begin
							s_mosi<=p_addr[23:16];
						end
						4:begin
							s_mosi<=p_addr[15:8];
						end
				end
				1'b1:begin
					case(fdcount)
						1:begin
							s_mosi<=8'b00000010;
						end
						2:begin
							s_mosi<=p_addr[31:24];
						end
						3:begin
							s_mosi<=p_addr[23:16];
						end
						4:begin
							s_mosi<=p_addr[15:8];
						end
				end
		end
		else (status==2'b10) begin
			case(p_write)
				1'b0:begin
					case(fdcount)
						1:begin
							p_data_out[31:24]<=s_miso;
						end
						2:begin
							p_data_out[23:16]<=s_miso;
						end
						3:begin
							p_data_out[15:8]<=s_miso;
						end
						4:begin
							p_data_out[7:0]<=s_miso;
						end
				end
				1'b1:begin
					case(fdcount)
						1:begin
							s_mosi<=p_data_out[31:24];
						end
						2:begin
							s_mosi<=p_data_out[23:16];
						end
						3:begin
							s_mosi<=p_data_out[15:8];
						end
						4:begin
							s_mosi<=p_data_out[7:0];
						end
				end
		end
	end



	fdivision divider(.clk_out(s_clk),.clk_in(p_clk),.rst(1'b1));


endmodule