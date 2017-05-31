`timescale 1 ns / 100 ps
`define ASIZE	22
`define DSIZE	8
module norflash_driver(
						//输入
						sys_clk,
						sys_rst_n,
						k1_n,

						//输出
						flash_req_o,
						sys_cmd_o,
						//read
						sys_rd_addr_o,
						//write
						sys_wr_addr_o,
						sys_wr_data_o
						);

	input sys_clk;
	input sys_rst_n;
	input k1_n;

	output flash_req_o;
	output [2:0] sys_cmd_o;
	//read
	output [`ASIZE-1:0] sys_rd_addr_o;
	//write
	output [`ASIZE-1:0] sys_wr_addr_o;
	output [`DSIZE-1:0] sys_wr_data_o;

	//capture the negedge of k1_n
	reg k1_r = 1;
	always @ (posedge sys_clk) begin
		if(sys_rst_n == 1'b0)	
			k1_r <= 1;
		else 
			k1_r <= k1_n;
	end

	wire k1_neg = ~k1_n & k1_r;

	//generate  flash_req_o
	reg flash_req_o = 0;
	always @ (posedge sys_clk) begin
		if(sys_rst_n == 1'b0) 
			flash_req_o <= 0;
		else if(k1_neg) 
			flash_req_o <= 1;
		else 
			flash_req_o <= 0;
	end

	//generate sys_cmd_o and sys_rd_addr_o
	reg [2:0] sys_cmd_o = 0;
	reg [`ASIZE-1:0] sys_rd_addr_o = 0;
	reg [`ASIZE-1:0] sys_wr_addr_o = 0;
	reg [`DSIZE-1:0] sys_wr_data_o = 0;
	reg [1:0] lut_index = 0;

	//generate lut_index
	always @ (posedge sys_clk) begin
		if(sys_rst_n == 1'b0) begin
			lut_index <= 0;
		end
		else if(k1_neg) begin
			lut_index <= lut_index + 1'd1;
		end
		else begin
			lut_index <= lut_index;
		end
	end

	always @ (posedge sys_clk) begin
		case(lut_index)
		2'd3:begin
				sys_cmd_o <= 3'b000;		// off set no meaning
				sys_wr_addr_o <= sys_wr_addr_o;
				sys_wr_data_o <= sys_wr_data_o;
				sys_rd_addr_o <= sys_rd_addr_o;
			end
		2'd0:begin
				sys_cmd_o <= 3'b010;		//sector eraser
				sys_wr_addr_o[21:13] <= 9'b0_0000_0001;//sector1
				sys_wr_addr_o[12:0] <= 13'd0;
				sys_wr_data_o <= sys_wr_data_o;
				sys_rd_addr_o <= `ASIZE'd0;
			end
		2'd1:begin
				sys_cmd_o <= 3'b001;		//write 1 byte
				sys_wr_addr_o[21:13] <= 9'b0_0000_0001;//sector1
				sys_wr_addr_o[12:0] <= 13'd0;
				sys_wr_data_o <= `DSIZE'hCC;//写數據內容
				sys_rd_addr_o <= `ASIZE'h00;
			end		
		2'd2:begin
				sys_cmd_o <= 3'b000;		//read 1 byte
				sys_wr_addr_o <= sys_wr_addr_o;
				sys_wr_data_o <= sys_wr_data_o;
				sys_rd_addr_o[21:13] <= 9'b0_0000_0001;//sector1
				sys_rd_addr_o[12:0] <= 13'd0;
			end
		endcase
	end
endmodule
