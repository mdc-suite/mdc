module fifo_small #(
       parameter depth = 64,  // FIFO depth (number of cells)
       parameter size = 8  	  // FIFO width (size in bits of each cell)
)(
		 output reg full,
         input [size-1:0] datain,
         input enw,
         output reg empty,
         output [size-1:0] dataout,
         input enr,
         input clk,
         input rst
);

 parameter ad_Max = depth-1;
 parameter ad_Min = 0;
 
 reg [size-1:0] tmp [0:depth-1];
 reg [5:0] address = ad_Max;

 reg we_a,enr_c,enw_c;
 reg [5:0] readaddr;
 reg [5:0] writeaddr;
 
integer i;

     always@(posedge clk)             
     begin
         if (enr==1 && enw==0)    
           for (i=0; i<=ad_Max-1; i=i+1)
             tmp[i+1] <= tmp[i];
         
         if (enw==1 && enr==1)    
           if (address == ad_Max)   
             tmp[address]<=datain;       
           else
             for (i=0; i<=ad_Max-1; i=i+1)
               tmp[i+1] <= tmp[i];
			 tmp[address+1]<=datain;	 
         if (enw==1 && enr==0)     
           tmp[address]<=datain;
	 end

     always@(posedge clk or negedge rst)          
     begin
       if ( rst==0 )  
         address <= ad_Max;
       else begin
           if (enr == 1 && enw==0 && address < ad_Max)
               address <= address + 1;
           if (enw == 1 && enr==0 && address > ad_Min)
               address <= address - 1; 
           if (enw == 1 && enr==1 && address == ad_Max)
               address <= address;
       end
     end


   always@(address or enw or enr)  
   begin
        if (  address > ad_Max-1 )
           empty <= 1'b1;
         else
           empty <= 1'b0;
        if ( address < ad_Min+1 ) 
           full <= 1'b1;
         else
           full <= 1'b0;
	end
   
   assign dataout = tmp[depth-1];

  endmodule
