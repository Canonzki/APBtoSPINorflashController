`timescale 1 ns / 100 ps
`define APBBITWIDE 32
`define SPIBITWIDE 8



module controller(
		//amba引脚
		p_clk,     //时钟
		p_addr,    //地址线最高32bit
		p_write,   //写信号高位表示要写
		p_sel_x,   //片选信号，默认置1，表示永久选中该设备
		p_enable,  //使能信号高电平有效
		p_wdata,    //数据线，最高32bit，该引脚为out类型，读和写的数据都要通过它
		p_rdata,    //数据线，最高32bit，该引脚为in类型，读和写的数据都要通过它
		//spi引脚
		s_miso,     //主设备输入，从设备输出，在这里controller是从设备，所以是个out类型的引脚
		s_mosi,     //主设备输出，从设备输入，在这里controller是主设备，所以是个输入的引脚
		s_clk,      //时钟位，由主设备产生，所以是个out类型的引脚
		s_css,		//从设备使能信号，同样由主设备输出，是个out类型的引脚,低位有效
	);

	//amba引脚
	input p_clk;
	input [`APBBITWIDE-1:0] p_addr;
	input p_write;
	input p_sel_x;
	input p_enable;

	input [`APBBITWIDE-1:0] p_wdata;
	output [`APBBITWIDE-1:0] p_rdata;

	//spi引脚
	input [`SPIBITWIDE-1:0] s_miso;
	output [`SPIBITWIDE-1:0] s_mosi;
	
	output s_clk;
	output s_css;

	wire p_clk;
	wire s_clk;

	wire [`SPIBITWIDE-1:0] s_miso;

	reg [`SPIBITWIDE-1:0] s_mosi;

	reg bpflag = 1;

	//状态寄存器两颗，x
	reg [1:0]status;
	reg [`APBBITWIDE-1:0] fdcount;

	//数据双工通信控制
	wire [`APBBITWIDE-1:0] p_rdata;
	reg [`APBBITWIDE-1:0] p_data_r;
	reg [`APBBITWIDE-1:0] p_data_w;

	assign s_clk = bpflag & p_sel_x;

	always 
		#1 bpflag = ~bpflag;


	always @(*) begin
		p_data_w = p_wdata;
	end

	assign p_rdata[`APBBITWIDE-1:0] = (fdcount >= 8 && status == 2'b10)?p_data_r:32'd0;
	assign s_css = ~p_sel_x;

	//重置逻辑
	always @(*) begin
		if (p_sel_x == 1'b0) begin
			status = 2'b00;
		end
	end

	//状态控制逻辑
	always @(negedge p_clk) begin
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

	always @(posedge p_clk) begin
		fdcount = 8'b00000000;
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
						end
						2:begin
							s_mosi = p_addr[31:24];
						end
						3:begin
							s_mosi = p_addr[23:16];
						end
						4:begin
							s_mosi = p_addr[15:8];
						end
					 endcase
				end
				1'b1:begin
					case(fdcount)
						1:begin
							s_mosi = 8'b00000010;
						end
						2:begin
							s_mosi = p_addr[31:24];
						end
						3:begin
							s_mosi = p_addr[23:16];
						end
						4:begin
							s_mosi = p_addr[15:8];
						end
					endcase
				end
			endcase
		end
		else if (status==2'b10) begin
			case(p_write)
				1'b0:begin
					case(fdcount)
						5:begin
							p_data_r[31:24] <= s_miso;
						end
						6:begin
							p_data_r[23:16] <= s_miso;
						end
						7:begin
							p_data_r[15:8] <= s_miso;
						end
						8:begin
							p_data_r[7:0] <= s_miso;
						end
					endcase//
				end
				1'b1:begin
					case(fdcount)
						5:begin
							s_mosi = p_data_w[31:24];
						end
						6:begin
							s_mosi = p_data_w[23:16];
						end
						7:begin
							s_mosi = p_data_w[15:8];
						end
						8:begin
							s_mosi = p_data_w[7:0];
						end
					endcase
				end
			endcase
		end
	end
endmodule