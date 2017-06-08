`timescale 1 ns / 100 ps
`define APBBITWIDE 32
`define SPIBITWIDE 8
`define LINEWIDE 32


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
	input [`LINEWIDE-1:0] p_addr;
	input p_write;
	input p_sel_x;
	input p_enable;

	input [`LINEWIDE-1:0] p_wdata;
	output [`LINEWIDE-1:0] p_rdata;

	//spi引脚
	input [`LINEWIDE-1:0] s_miso;
	output [`LINEWIDE-1:0] s_mosi;
	
	output s_clk;
	output s_css;

	wire p_clk;
	wire s_clk;

	wire [`LINEWIDE-1:0] s_miso;

	reg [`LINEWIDE-1:0] s_mosi = 0;

	reg bpflag = 1 = 0;

	//状态寄存器两颗，x
	reg [1:0]status;
	reg [`LINEWIDE-1:0] fdcount = 0;

	//数据双工通信控制
	wire [`LINEWIDE-1:0] p_rdata;
	reg [`LINEWIDE-1:0] p_data_r = 0;
	reg [`LINEWIDE-1:0] p_data_w = 0;

	reg CPOL = 0;
	reg CPHA = 0;

	assign s_clk = (CPOL==0)?(p_clk & p_sel_x):(~(p_clk & p_sel_x));

	always @(*) begin
		p_data_w = p_wdata;
	end

	assign p_rdata[`LINEWIDE-1:0] = (fdcount >= 8 && status == 2'b10)?p_data_r:32'd0;
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

	always @(posedge p_sel_x) begin
		fdcount = 8'b00000000;
	end

	//计数器，计算分频器分频之后当权处于子周期中的第fdcount周期
	always @(posedge s_clk) begin
		if(CPHA==CPOL) begin
			fdcount = fdcount + 1;
		end
	end

	//计数器，计算分频器分频之后当权处于子周期中的第fdcount周期
	always @(negedge s_clk) begin
		if(CPHA!=CPOL) begin
			fdcount = fdcount + 1;
		end
	end



	//当传输开始时
	always @(posedge s_clk) begin
		if(CPHA==CPOL) begin
			//片选阶段
			if (status==2'b01) begin
				case(p_write)
					1'b0:begin
						//读操作
						case(fdcount)
							1:begin
								s_mosi[31:8] <= p_addr[31:8];
								s_mosi[7:0] <= 8'b00000010;
							end
						endcase
					end
					1'b1:begin
						//写操作
						case(fdcount)
							1:begin
								s_mosi[31:8] <= p_addr[31:8];
								s_mosi[7:0] <= 8'b00000010;
							end
						endcase
					end
				endcase
			end
			//使能阶段
			else if (status==2'b10) begin
				case(p_write)
					//读操作
					1'b0:begin
						case(fdcount)
							2:begin
								p_data_r[31:0] <= s_miso[31:0];
							end
						endcase//
					end
					//写操作
					1'b1:begin
						case(fdcount)
							2:begin
								s_mosi[31:0] = p_data_w[31:0];
							end
						endcase
					end
				endcase
			end
		end
	end

		//当传输开始时
	always @(negedge s_clk) begin
		if(CPHA!=CPOL) begin
			//片选阶段
			if (status==2'b01) begin
				case(p_write)
					1'b0:begin
						//读操作
						case(fdcount)
							1:begin
								s_mosi[31:8] <= p_addr[31:8];
								s_mosi[7:0] <= 8'b00000010;
							end
						endcase
					end
					1'b1:begin
						//写操作
						case(fdcount)
							1:begin
								s_mosi[31:8] <= p_addr[31:8];
								s_mosi[7:0] <= 8'b00000010;
							end
						endcase
					end
				endcase
			end
			//使能阶段
			else if (status==2'b10) begin
				case(p_write)
					//读操作
					1'b0:begin
						case(fdcount)
							2:begin
								p_data_r[31:0] <= s_miso[31:0];
							end
						endcase//
					end
					//写操作
					1'b1:begin
						case(fdcount)
							2:begin
								s_mosi[31:0] = p_data_w[31:0];
							end
						endcase
					end
				endcase
			end
		end
	end
endmodule