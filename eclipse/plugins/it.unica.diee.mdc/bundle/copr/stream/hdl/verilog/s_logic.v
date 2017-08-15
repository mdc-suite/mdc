`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:17:29 02/21/2015 
// Design Name: 
// Module Name:    s_logic 
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
module s_logic(
    count,
	 size,
	 endcount
	 );
	 
parameter SIZECOUNT=12;

input wire [SIZECOUNT-1:0] count;
input wire [SIZECOUNT-1:0] size;	
output wire endcount;

// endcount generation
   assign endcount = size==count; 


endmodule
