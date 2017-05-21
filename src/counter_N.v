module  counter_N  (clk, fin, reset, count_N);//利用clk对fin脉冲的测量并给出N值     
	input    clk, fin, reset;   
	output   [14:0] count_N;    
	reg      [14:0] count_N;     
	reg      [15:0] cnt;    
	reg      cnt_en;   
	reg      load;    
	wire     cnt_clr;                 

	always @ (posedge fin ) begin//fin上升沿到的时候，产生各种标志以便后面控制      
		if (reset) begin              
			cnt_en=0;              
			load=1;           
		end       
		else begin               
			cnt_en=~cnt_en;              
			load=~cnt_en;           
		end     
	end           

	assign cnt_clr=~(~fin & load);  

	always @(posedge clk or negedge cnt_clr) begin
		if (!cnt_clr)               
			cnt=0;        
		else if (cnt_en)  begin                 
			if (cnt==65536)                  
				cnt=0;    	           
			else                   
				cnt=cnt+1;                
		end    
	end  

	always @ (posedge load) begin       
		count_N=cnt/2;      //这里取fin周期的一半    
	end 
endmodule