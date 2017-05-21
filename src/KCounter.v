module KCounter(Kclock,reset,dnup,enable,Kmode,carry,borrow); 
	input Kclock;    //系统时钟信号  
	input reset;    //全局复位信号,高电平复位 
	input dnup;    //鉴相器输出的加减控制信号  
	input enable; //可逆计数器计数允许信号，高电平有效 
	input [2:0]Kmode;   //计数器模值设置信号 
	output carry;     //进位脉冲输出信号 
	output borrow;    //借位脉冲输出信号 
	wire  carry,borrow; 
	reg [8:0]Count; //可逆计数器 
	reg [8:0]Ktop; //预设模值寄存器  //根据计数器模值设置信号Kmode来设置预设模值寄存器的值 
	always @(Kmode) begin          
		case(Kmode)           
			3'b001:Ktop<=7;           
			3'b010:Ktop<=15;           
			3'b011:Ktop<=31;           
			3'b100:Ktop<=63;           
			3'b101:Ktop<=127;           
			3'b110:Ktop<=255;           
			3'b111:Ktop<=511;           
			default:Ktop<=15;         
		endcase     
	end   //根据鉴相器输出的加减控制信号dnup进行可逆计数器的加减运算 

	always @(posedge Kclock or posedge reset) begin      
		if(reset)       
			Count<=0;      
		else if(enable) begin            
			if(!dnup) begin                 
				if(Count==Ktop)                   
					Count<=0; 
				else
					Count<=Count+1; 
				end         
			else begin                
				if(Count==0)                  
					Count<=Ktop;                
				else                   
					Count<=Count-1;               
			end       
		end 
	end   //输出进位脉冲carry和借位脉冲borrow 

	assign carry=enable&(!dnup)&(Count==Ktop); 
	assign borrow=enable&dnup&(Count==0); 
endmodule 