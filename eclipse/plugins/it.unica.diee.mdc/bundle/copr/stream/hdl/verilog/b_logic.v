`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:13:31 02/21/2015 
// Design Name: 
// Module Name:    b_logic 
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
module b_logic(
    count,
	 sizeburst,
	 endburst
	 );
	 
parameter SIZEBURST=8;
parameter SIZECOUNT=12;

input wire [SIZECOUNT-1:0] count;
input wire [SIZEBURST-1:0] sizeburst;
output wire endburst;

wire endburst_in;
wire [SIZEBURST-1:0] numb;
wire [SIZEBURST-1:0] rest;

// endburst generation 
	assign endburst_in = endburst; //((count_out+1)%sizeburst)==0;
	assign {numb,rest} = {(count+1),8'b0}>>sizeburst;
	assign endburst = rest==0;	 

endmodule
