`timescale 1 ns / 100 ps
//`define SIM
`define ASIZE	22
`define DSIZE	8	
`define S29AL032D70TFI04
`define SYS_CLK	50000000
//version 0.0
//前级控制模块功能指令集 sys_cmd_i
//000:single byte read(1 cycle)
//001:single byte write(4 cycle)
//010:sect erase

module norflash_ctrl(//common
						sys_clk,
						sys_rst_n,
						sys_cmd_i,
						flash_req_i,
						flash_ack_o,
						//read
						sys_rd_addr_i,
						sys_data_o,
						//write
						sys_wr_addr_i,
						sys_data_i,
						//flash
						flash_addr,
						flash_data,
						flash_ce_n,
						flash_oe_n,
						flash_we_n,
						flash_rst_n 
					);

	`ifdef S29AL032D70TFI04
		`define CLAP_WIDTH	3	//器件最小周期70ns，根据系统时钟此模块设置为80ns
		`define CLAP	4
		`define SECT_TIME	35000000		// 單次擦除需要0.7秒時間間隙，主時鐘20ns
		`define BYTE_WR_TIME	452			//單字節寫需要9微妙時間間隙，主時鐘20ns
	`endif
	`ifdef SIM
		parameter ST_WIDTH = 72;
		parameter 
			IDLE = "IDLE.....",
			BYTE_RD = "BYTE_RD..",
			BYTE_WR1 = "BYTE_WR1.",
			BYTE_WR2 = "BYTE_WR2.",
			BYTE_WR3 = "BYTE_WR3.",
			BYTE_WR4 = "BYTE_WR4.",
			SECT_ERA1 = "SECT_ERA1",
			SECT_ERA2 = "SECT_ERA2",
			SECT_ERA3 = "SECT_ERA3",
			SECT_ERA4 = "SECT_ERA4",
			SECT_ERA5 = "SECT_ERA5",
			SECT_ERA6  = "SECT_ERA6",
			SECT_WAIT = "SECT_WAIT",
			BYTE_WR_WAIT = "BYTE_WR_W";
	`else
		parameter ST_WIDTH = 14;
	`define FSM	14
		parameter		
			IDLE = `FSM'b00_0000_0000_0001,
			BYTE_RD = `FSM'b00_0000_0000_0010,
			BYTE_WR1 = `FSM'b00_0000_0000_0100,
			BYTE_WR2 = `FSM'b00_0000_0000_1000,
			BYTE_WR3 = `FSM'b00_0000_0001_0000,
			BYTE_WR4 = `FSM'b00_0000_0010_0000,
			SECT_ERA1 = `FSM'b00_0000_0100_0000,
			SECT_ERA2 = `FSM'b00_0000_1000_0000,
			SECT_ERA3 = `FSM'b00_0001_0000_0000,
			SECT_ERA4 = `FSM'b00_0010_0000_0000,
			SECT_ERA5 = `FSM'b00_0100_0000_0000,
			SECT_ERA6 = `FSM'b00_1000_0000_0000,
			SECT_WAIT = `FSM'b01_0000_0000_0000,
			BYTE_WR_WAIT = `FSM'b10_0000_0000_0000;
	`endif
	//common
	input sys_clk;
	input sys_rst_n;
	input [2:0] sys_cmd_i;		//前级控制指令变化
	input flash_req_i;				//前级控制指令请求脉冲，配合指令
	output flash_ack_o;
	//read
	input [`ASIZE-1:0] sys_rd_addr_i;
	output [`DSIZE-1:0] sys_data_o;
	//write
	input [`DSIZE-1:0] sys_data_i;
	input [`ASIZE-1:0] sys_wr_addr_i;
	//flash
	output [`ASIZE-1:0] flash_addr;
	inout [`DSIZE-1:0] flash_data;	//暂时先设置为读方向
	output flash_we_n;
	output flash_ce_n;
	output flash_oe_n;
	output flash_rst_n;

	//capture the posedge of flash_req_i;
	reg flash_req_r = 0;

	always @ (posedge sys_clk) begin
		if(sys_rst_n == 1'b0) flash_req_r <= 0;
		else flash_req_r <= flash_req_i;
	end

	wire rqst_edge = flash_req_i & ~flash_req_r;//检测上升沿
	//decode cmd 指令译码 并生成 内部控制信号
	reg do_byte_rd = 0;		//单字节读
	reg do_sect_era = 0;	//整片擦出
	reg do_byte_wr = 0;		//单字节写

	always @ (posedge sys_clk) begin

		if(sys_rst_n == 1'b0) begin
			do_byte_rd <= 0;
			do_sect_era <= 0;
			do_byte_wr <= 0;
		end

		else if(flash_ack_o) begin
			do_byte_rd <= 0;
			do_sect_era <= 0;
			do_byte_wr <= 0;
		end

		else if(rqst_edge) begin
			case(sys_cmd_i)

				3'd0:begin
					do_byte_rd <= 1;			//读有效
					do_sect_era <= 0;
					do_byte_wr <= 0;
				end

				3'd1:begin						//写有效
					do_byte_wr <= 1;
					do_byte_rd <= 0;
					do_sect_era <= 0;
				end

				3'd2:begin								//整片擦除有效
					do_sect_era <= 1;
					do_byte_wr <= 0;
					do_byte_rd <= 0;
				end

				default:begin
					do_byte_rd <= 0;
					do_sect_era <= 0;
					do_byte_wr <= 0;
				end

			endcase
		end
		else begin
			do_byte_rd <= do_byte_rd;
			do_sect_era <= do_sect_era;
			do_byte_wr <= do_byte_wr;
		end
	end
	//combine all does
	wire do_process = do_byte_rd|do_sect_era|do_byte_wr;
	//GENERATE CLOCK CLAP
	reg [`CLAP_WIDTH-1:0] clk_clap = `CLAP_WIDTH'd0;

	always @ (posedge sys_clk) begin
		if(sys_rst_n == 1'b0)	
			clk_clap <= `CLAP_WIDTH'd0;
		else if(flash_ack_o) 
			clk_clap <= `CLAP_WIDTH'd0;
		else if(clk_clap == `CLAP) 
			clk_clap <= `CLAP_WIDTH'd1;
		else if(do_process) 
			clk_clap <= clk_clap + 1'd1;
		else 
			clk_clap <= clk_clap;
	end
	//fsm
	reg [ST_WIDTH-1:0] c_st = IDLE;
	reg [ST_WIDTH-1:0] n_st = IDLE;
	reg [31:0] sect_time_cnt = 0;	//延遲扇區擦除所需時間
	//generate sect_time_cnt
	//wire sect_era6 = ((c_st == SECT_ERA6)&&(clk_clap == `CLAP_WIDTH'd`CLAP))?1'b1:1'b0;//擦寫最後一個週期的最後一個脉衝
	always @ (posedge sys_clk) begin
		if(sys_rst_n == 1'b0) 
			sect_time_cnt <= 0;
		else if((c_st == SECT_WAIT)&&(sect_time_cnt < `SECT_TIME-1))	
			sect_time_cnt <= sect_time_cnt + 1'd1;
		else if(sect_time_cnt == `SECT_TIME-1) 
			sect_time_cnt <= 0;
		else 
			sect_time_cnt <= sect_time_cnt;
	end
		//GENERATE BYTE_WR_TIME_CNT
	reg [8:0] byte_wr_time_cnt = 0;

	always @ (posedge sys_clk) begin
		if(sys_rst_n == 1'b0)	byte_wr_time_cnt <= 0;
		else if((c_st == BYTE_WR_WAIT)&&(byte_wr_time_cnt < `BYTE_WR_TIME-1))	byte_wr_time_cnt <= byte_wr_time_cnt + 1'd1;
		else if(byte_wr_time_cnt == `BYTE_WR_TIME-1) byte_wr_time_cnt <= 0;
		else byte_wr_time_cnt <= byte_wr_time_cnt;
	end
		//fsm-1
	always @ (posedge sys_clk) begin
		if(sys_rst_n == 1'b0) 
			c_st <= IDLE;
		else c_st <= n_st;
	end

	wire [2:0] do_type = {do_sect_era,do_byte_rd,do_byte_wr};		//
	//fsm-2
	always @ (*) begin
		case(c_st)
			IDLE:begin
				case(do_type)
					3'b001:n_st = BYTE_WR1;
					3'b010:n_st = BYTE_RD;
					3'b100:n_st = SECT_ERA1;
					default:n_st = IDLE;
				endcase
			end

			BYTE_RD:begin
				n_st = (clk_clap == `CLAP_WIDTH'd`CLAP)?IDLE:BYTE_RD;
			end

			BYTE_WR1:begin
				n_st = (clk_clap == `CLAP_WIDTH'd`CLAP)?BYTE_WR2:BYTE_WR1;
			end

			BYTE_WR2:begin
				n_st = (clk_clap == `CLAP_WIDTH'd`CLAP)?BYTE_WR3:BYTE_WR2;
			end

			BYTE_WR3:begin
				n_st = (clk_clap == `CLAP_WIDTH'd`CLAP)?BYTE_WR4:BYTE_WR3;
			end

			BYTE_WR4:begin
				n_st = (clk_clap == `CLAP_WIDTH'd`CLAP)?BYTE_WR_WAIT:BYTE_WR4;
			end

			BYTE_WR_WAIT:begin
				n_st = ((clk_clap == `CLAP_WIDTH'd`CLAP)&&(byte_wr_time_cnt == `BYTE_WR_TIME-1))?IDLE:BYTE_WR_WAIT;
			end

			SECT_ERA1:begin
				n_st = (clk_clap == `CLAP_WIDTH'd`CLAP)?SECT_ERA2:SECT_ERA1;
			end

			SECT_ERA2:begin
				n_st = (clk_clap == `CLAP_WIDTH'd`CLAP)?SECT_ERA3:SECT_ERA2;
			end

			SECT_ERA3:begin
				n_st = (clk_clap == `CLAP_WIDTH'd`CLAP)?SECT_ERA4:SECT_ERA3;
			end

			SECT_ERA4:begin
				n_st = (clk_clap == `CLAP_WIDTH'd`CLAP)?SECT_ERA5:SECT_ERA4;
			end

			SECT_ERA5:begin
				n_st = (clk_clap == `CLAP_WIDTH'd`CLAP)?SECT_ERA6:SECT_ERA5;
			end

			SECT_ERA6:begin
				n_st = (clk_clap == `CLAP_WIDTH'd`CLAP)?SECT_WAIT:SECT_ERA6;
			end

			SECT_WAIT:begin
				n_st = ((clk_clap == `CLAP_WIDTH'd`CLAP)&&(sect_time_cnt == `SECT_TIME-1))?IDLE:SECT_WAIT;
			end

			default:begin
				n_st = IDLE;
			end
		endcase
	end
	//fsm-3
	reg [3:0] cmd_r = 0;
	reg [`DSIZE-1:0] sys_data_o = 0;
	reg [`ASIZE-1:0] flash_addr = 0; 
	reg [`DSIZE-1:0] data_buf = 0;
	reg link = 0;
	always @ (posedge sys_clk) begin
		if(1'b0 == sys_rst_n) begin
			cmd_r <= 4'b0011;
			flash_addr <= 0;
			data_buf <= 0;
			sys_data_o <= 0;
			link <= 0;
		end
		else begin
			case(n_st)

				IDLE:begin
					cmd_r <= 4'b0011;
					flash_addr <= flash_addr;
					data_buf <= data_buf;
					sys_data_o <= sys_data_o;
					link <= 0;
				end

				BYTE_RD:begin
					cmd_r <= 4'b0011;
					flash_addr <= sys_rd_addr_i;
					data_buf <= data_buf;		//hold
					sys_data_o <= (clk_clap == `CLAP_WIDTH'd2)?flash_data:sys_data_o;
					link <= 0;
				end

				SECT_ERA1:begin
					cmd_r <= (clk_clap == `CLAP_WIDTH'd2||clk_clap ==`CLAP_WIDTH'd1)?4'b0101:4'b0111;
					flash_addr <= `ASIZE'h000aaa;
					data_buf <= `DSIZE'haa;
					sys_data_o <= sys_data_o;
					link <= 1;
				end

				SECT_ERA2:begin
					cmd_r <= (clk_clap == `CLAP_WIDTH'd2||clk_clap ==`CLAP_WIDTH'd1)?4'b0101:4'b0111;
					flash_addr <= `ASIZE'h000555;
					data_buf <= `DSIZE'h55;
					sys_data_o <= sys_data_o;
					link <= 1;
				end

				SECT_ERA3:begin
					cmd_r <= (clk_clap == `CLAP_WIDTH'd2||clk_clap ==`CLAP_WIDTH'd1)?4'b0101:4'b0111;
					flash_addr <= `ASIZE'h000aaa;
					data_buf <= `DSIZE'h80;
					sys_data_o <= sys_data_o;
					link <= 1;
				end

				SECT_ERA4:begin
					cmd_r <= (clk_clap == `CLAP_WIDTH'd2||clk_clap ==`CLAP_WIDTH'd1)?4'b0101:4'b0111;
					flash_addr <= `ASIZE'h000aaa;
					data_buf <= `DSIZE'haa;
					sys_data_o <= sys_data_o;
					link <= 1;
				end

				SECT_ERA5:begin
					cmd_r <= (clk_clap == `CLAP_WIDTH'd2||clk_clap ==`CLAP_WIDTH'd1)?4'b0101:4'b0111;
					flash_addr <= `ASIZE'h000555;
					data_buf <= `DSIZE'h55;
					sys_data_o <= sys_data_o;
					link <= 1;
				end

				SECT_ERA6:begin
					cmd_r <= (clk_clap == `CLAP_WIDTH'd2||clk_clap ==`CLAP_WIDTH'd1)?4'b0101:4'b0111;
					flash_addr <= sys_wr_addr_i;		//sector address
					data_buf <= `DSIZE'h30;
					sys_data_o <= sys_data_o;
					link <= 1;
				end

				SECT_WAIT:begin												//wait for rphysical sector erase time 
					cmd_r <= 4'b1111;
					flash_addr <= flash_addr;
					data_buf <= data_buf;
					sys_data_o <= sys_data_o;
					link <= 0;
				end

				BYTE_WR1:begin
					cmd_r <= (clk_clap == `CLAP_WIDTH'd2||clk_clap ==`CLAP_WIDTH'd1)?4'b0101:4'b0111;
					flash_addr <= `ASIZE'h000aaa;
					data_buf <= `DSIZE'haa;
					sys_data_o <= sys_data_o;
					link <= 1;
				end

				BYTE_WR2:begin
					cmd_r <= (clk_clap == `CLAP_WIDTH'd2||clk_clap ==`CLAP_WIDTH'd1)?4'b0101:4'b0111;
					flash_addr <= `ASIZE'h000555;
					data_buf <= `DSIZE'h55;
					link <= 1;
				end

				BYTE_WR3:begin
					cmd_r <= (clk_clap == `CLAP_WIDTH'd2||clk_clap ==`CLAP_WIDTH'd1)?4'b0101:4'b0111;
					flash_addr <= `ASIZE'h000aaa;
					data_buf <= `DSIZE'ha0;
					sys_data_o <= sys_data_o;
					link <= 1;
				end

				BYTE_WR4:begin
					cmd_r <= (clk_clap == `CLAP_WIDTH'd2||clk_clap ==`CLAP_WIDTH'd1)?4'b0101:4'b0111;
					flash_addr <= sys_wr_addr_i;
					data_buf <= sys_data_i;
					sys_data_o <= sys_data_o;
					link <= 1;
				end

				BYTE_WR_WAIT:begin												//wait for rphysical sPROGRAM time 
					cmd_r <= 4'b1111;
					flash_addr <= flash_addr;
					data_buf <= data_buf;
					sys_data_o <= sys_data_o;
					link <= 0;
				end

				default:begin
					cmd_r <= 4'b0011;
					flash_addr <= flash_addr;
					data_buf <= data_buf;
					link <= link;
					sys_data_o <= sys_data_o;
				end
			endcase
		end 
	end
	//assign
	assign flash_data = (link)?data_buf:`DSIZE'hzz;
	wire flash_byte_rd_ack = ((c_st == BYTE_RD)&&(clk_clap == `CLAP_WIDTH'd`CLAP))?1'b1:1'b0;
	wire flash_byte_wr_ack = ((c_st == BYTE_WR_WAIT)&&(byte_wr_time_cnt == `BYTE_WR_TIME-1))?1'b1:1'b0;
	wire flash_sect_era_ack = ((c_st == SECT_WAIT)&&(sect_time_cnt == `SECT_TIME-1))?1'b1:1'b0;
	wire flash_ack_o = flash_byte_rd_ack | flash_byte_wr_ack | flash_sect_era_ack;
	assign {flash_ce_n,flash_oe_n,flash_we_n,flash_rst_n} = cmd_r;
endmodule