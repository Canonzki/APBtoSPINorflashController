module IDCounter (IDclock,reset,inc,dec,IDout);//脉冲增减模块 
	input IDclock,reset,inc,dec; 
	output IDout; 
	reg IDout;  
	reg inc_new,dec_new,inc_pulse,dec_pulse; 
	reg delayed,advanced,Tff; 

	always @(posedge IDclock) begin         
		if(!inc) begin 
			inc_new<=1;              
			inc_pulse<=0;            
		end        
		else if (inc_pulse) begin                  
			inc_new<=0;                 
			inc_pulse<=0;               
		end        
		else if (inc&&inc_new) begin                  
			inc_pulse<=1;                 
			inc_new<=0;                
		end            
		else begin 
			inc_pulse<=0;                  
			inc_new<=0;                
		end 
	end   

	always @(posedge IDclock) begin         
		if(!dec) begin               
			dec_new<=1;              
			dec_pulse<=0;         
		end        
		else if (dec_pulse) begin 
			dec_new<=0;               
			dec_pulse<=0;               
		end        
		else if (dec&&dec_new) begin                    
			dec_pulse<=1;                   
			dec_new<=0;                
		end            
		else begin                   
			dec_pulse<=0;                  
			dec_new<=0;                
		end 
	end   

	always@(posedge IDclock) begin       
		if (reset) begin  
			Tff<=0; 
			delayed<=1;
			advanced<=1; 
		end      
		else begin            
			if (inc_pulse) begin  
				advanced<=1;
				Tff<=!Tff; 
			end           
			else if(dec_pulse) begin 
				delayed<=1; 
				Tff<=!Tff;  
			end           
			else if (Tff==0) begin
				if(!advanced)                    
					Tff<=!Tff;                  
				else if(advanced) begin 
					Tff<=Tff; 
					advanced<=0; 
				end                
			end           
			else begin                    
				if (!delayed)                      
					Tff<=!Tff;                    
				else if(delayed) begin 
					Tff<=Tff;delayed<=0; 
				end                  
			end      
		end   	
	end  

	always @(IDclock or Tff) begin         
		if (Tff)          
			IDout=0;       
		else begin               
			if(IDclock)                  
				IDout=0;               
			else                 
				IDout=1;          
			end 
	end  
	 
endmodule