`timescale 1 ns / 100 ps

`define APBBITWIDE 32
`define SPIBITWIDE 8

module controller_test();

	reg p_clk;
	reg p_reset_n;
	reg [`APBBITWIDE-1:0] p_addr;
	reg p_write;
	reg p_sel_x;
	reg p_enable;
	reg [`APBBITWIDE-1:0] p_wdata;
	wire [`APBBITWIDE-1:0] p_rdata;
	reg [`SPIBITWIDE-1:0] s_miso;
	wire [`SPIBITWIDE-1:0] s_mosi;
	wire s_clk;
	wire s_css;

	reg [`SPIBITWIDE-1:0] en_write;
	reg [`APBBITWIDE-1:0] flash_addr = 0'd0;


	reg [`APBBITWIDE-1:0] flash0;
	reg [`APBBITWIDE-1:0] the_read_data;

	reg [`SPIBITWIDE-1:0] count = 8'b00000000;


	initial begin
		p_reset_n <= 1'b1;
		#4
		p_reset_n <= 1'b0;
		#8
		p_reset_n <= 1'b1;
	end

	initial begin
		p_clk <= 1'b0; //初始化clock引脚为0
		p_write <= 1'b0;
		p_sel_x <= 1'b0;
		p_enable <= 1'b0;
	end
		
	always @(*) begin
		the_read_data = p_rdata;
	end

	always 
		#8 p_clk = ~p_clk; //设置clock引脚电平的翻转



	
	initial begin
		#24
		p_write <= 1'b1;
		p_addr <= 32'd0;
		p_wdata <= 32'b11111111000000001111111100000000;
		p_sel_x <= 1'b1;
	end

	initial begin
		#56
		p_sel_x <= 1'b0;
	end


	initial begin
		#72
		p_sel_x <= 1'b1;
		//p_reset_n <= 1'b0;
		p_write <= 1'b0;
		p_addr <= 32'd0;
	end

	initial begin
		#40 p_enable = ~p_enable;
		#16 p_enable = ~p_enable;
		#32 p_enable = ~p_enable;
	end
		
	always @(posedge s_clk) begin
		count <= count + 1;
	end

	always @(negedge s_css) begin
		count <= 8'b00000000;
	end


	always @(posedge p_clk) begin
		case(count)
			1:begin
				en_write <= s_mosi;
			end 
			2:begin
				flash_addr[31:24] <= s_mosi;
			end
			3:begin
				flash_addr[23:16] <= s_mosi;
			end
			4:begin
				flash_addr[15:8] <= s_mosi;
			end
			5:begin
				if(flash_addr == 0'd0 && en_write == 8'b00000010) begin
					flash0[31:24] <= s_mosi;
				end
				else if(flash_addr == 0'd0 && en_write == 8'b00000001) begin
					s_miso <= flash0[31:24];
				end
			end
			6:begin
				if(flash_addr == 0'd0 && en_write == 8'b00000010) begin
					flash0[23:16] <= s_mosi;
				end
				else if(flash_addr == 0'd0 && en_write == 8'b00000001) begin
					s_miso <= flash0[23:16];
				end
			end
			7:begin
				if(flash_addr == 0'd0 && en_write == 8'b00000010) begin
					flash0[15:8] <= s_mosi;
				end
				else if(flash_addr == 0'd0 && en_write == 8'b00000001) begin
					s_miso <= flash0[15:8];
				end
			end
			8:begin
				if(flash_addr == 0'd0 && en_write == 8'b00000010) begin
					flash0[7:0] <= s_mosi;
				end
				else if(flash_addr == 0'd0 && en_write == 8'b00000001) begin
					s_miso <= flash0[7:0];
				end
			end
		endcase
	end


	controller norflash_contorller(
									.p_clk(p_clk),   
									.p_reset_n(p_reset_n),
									.p_addr(p_addr),  
									.p_write(p_write), 
									.p_sel_x(p_sel_x), 
									.p_enable(p_enable),
									.p_wdata(p_wdata),  
									.p_rdata(p_rdata),  
									//spi引脚
									.s_mosi(s_mosi),  
									.s_miso(s_miso),  
									.s_clk(s_clk),   
									.s_css(s_css),	
									);

	initial begin
		$fsdbDumpfile("test.fsdb");
		$fsdbDumpvars;
	end

	initial begin
		#104 $finish;
	end


endmodule