`timescale 1 ns / 100 ps

`define APBBITWIDE 32
`define SPIBITWIDE 8
`define LINEWIDE 32

module controller_test();

	reg p_clk = 0;
	reg [`LINEWIDE-1:0] p_addr = 0;
	reg p_write = 0;
	reg p_sel_x = 0;
	reg p_enable = 0;
	reg [`LINEWIDE-1:0] p_wdata = 0;
	wire [`LINEWIDE-1:0] p_rdata;
	reg [`LINEWIDE-1:0] s_miso = 0;
	wire [`LINEWIDE-1:0] s_mosi;
	wire s_clk;
	wire s_css;

	reg [`LINEWIDE-1:0] en_write = 0;
	reg [`LINEWIDE-1:0] flash_addr = 0'd0;


	reg [`LINEWIDE-1:0] flash0 = 0;
	reg [`LINEWIDE-1:0] the_read_data = 0;

	reg [`LINEWIDE-1:0] count = 8'b00000000;


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
		//p_sel_x <= 1'b1;
	end

	initial begin
		#56
		//p_sel_x <= 1'b0;
	end


	initial begin
		#72
		//p_sel_x <= 1'b1;
		p_write <= 1'b0;
		p_addr <= 32'd0;
	end

	initial begin
		#25 p_sel_x = 1'b1;
		#32 p_sel_x = 1'b0;
		#16 p_sel_x = 1'b1;
		#32 p_sel_x = 1'b0;
	end

	initial begin
		#41 p_enable = ~p_enable;
		#16 p_enable = ~p_enable;
		#32 p_enable = ~p_enable;
		#16 p_enable = ~p_enable;
	end
		
	always @(posedge s_clk) begin
		count = count + 1;
	end

	always @(negedge s_css) begin
		count <= 8'b00000000;
	end


	reg reg [`LINEWIDE-1:0] count_is_sb = 8'b00000000;

	always @(posedge s_clk) begin
	  count_is_sb = count;
	end

	always @(posedge s_clk) begin
		case(count)
			0:begin
				en_write = s_mosi[7:0];
				flash_addr[31:8] = s_mosi[31:8];
				if(flash_addr[31:8] == 24'd0 && en_write == 8'b00000001) begin
	    			s_miso[31:0] = flash0[31:0];
	    		end
			end 
			1:begin
				if(flash_addr[31:8] == 24'd0 && en_write == 8'b00000010) begin
					flash0[31:0] = s_mosi[31:0];
				end
				else if(flash_addr[31:8] == 24'd0 && en_write == 8'b00000001) begin
					s_miso[31:0] = flash0[31:0];
				end
			end
		endcase
	end


	controller norflash_contorller(
									.p_clk(p_clk),   
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
		#112 $finish;
	end


endmodule