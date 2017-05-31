`timescale 1 ns / 100 ps
`define ASIZE	22
`define DSIZE	8
module norflash(
					sys_clk,
					sys_rst_n,
					k1_n,
					//flash
					flash_data,
					flash_addr,
					flash_ce_n,
					flash_oe_n,
					flash_we_n,
					flash_rst_n
				);

	input sys_clk;
	input sys_rst_n;
	input k1_n;
	//flash
	inout [`DSIZE-1:0] flash_data;
	output [`ASIZE-1:0] flash_addr;
	output flash_ce_n;
	output flash_oe_n;
	output flash_we_n;
	output flash_rst_n;

	wire [2:0] sys_cmd;
	wire flash_req;
	wire [`ASIZE-1:0] sys_rd_addr;
	wire [`DSIZE-1:0] sys_data_o;

	wire [`ASIZE-1:0] sys_wr_addr;
	wire [`DSIZE-1:0] sys_wr_data;
	norflash_driver			nst_driver(
								.sys_clk(sys_clk),
								.sys_rst_n(sys_rst_n),
								.k1_n(k1_n),
								.flash_req_o(flash_req),
								.sys_cmd_o(sys_cmd),
								.sys_rd_addr_o(sys_rd_addr),
								//write
								.sys_wr_addr_o(sys_wr_addr),
								.sys_wr_data_o(sys_wr_data)
							);

	wire flash_ack;
	norflash_ctrl			inst_ctrl(//common
								.sys_clk(sys_clk),
								.sys_rst_n(sys_rst_n),
								.sys_cmd_i(sys_cmd),
								.flash_req_i(flash_req),
								.flash_ack_o(flash_ack),
								//write
								.sys_wr_addr_i(sys_wr_addr),
								.sys_data_i(sys_wr_data),
								//read
								.sys_rd_addr_i(sys_rd_addr),
								.sys_data_o(sys_data_o),
								//flash
								.flash_addr(flash_addr),
								.flash_data(flash_data),
								.flash_ce_n(flash_ce_n),
								.flash_oe_n(flash_oe_n),
								.flash_we_n(flash_we_n),
								.flash_rst_n(flash_rst_n)
							);
endmodule