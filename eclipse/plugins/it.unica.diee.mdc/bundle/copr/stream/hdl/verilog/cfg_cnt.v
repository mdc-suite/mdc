`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:48:09 02/13/2015 
// Design Name: 
// Module Name:    cfg_cnt 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module cfg_cnt(
   clk,
	reset,	
	go,
	pointer,
	endldcr
	);

parameter MAX_CNT = 3;
parameter SIZE_PTR = 2;

input wire clk;
input wire reset;
input wire go;
output reg [SIZE_PTR-1:0] pointer;
output reg endldcr;

reg [SIZE_PTR-1:0] pointer_nxt;

// counter register
always @ (posedge clk or posedge reset)
  begin
    if (reset)
	    pointer <= 0;
	 else 
       pointer <= pointer_nxt;
  end
	
// counter logic 
always @ (pointer or go)
  begin
   if (go)
	   begin
	   if (pointer==MAX_CNT)
		   pointer_nxt <= 0;
		else 
         pointer_nxt <= pointer+1;
	   end		
	else 
      pointer_nxt <= pointer;		
  end		
	
// endload logic			
always @ (pointer)
   begin
    if (pointer==MAX_CNT) endldcr<=1;
    else	 endldcr<=0;
	end

endmodule
