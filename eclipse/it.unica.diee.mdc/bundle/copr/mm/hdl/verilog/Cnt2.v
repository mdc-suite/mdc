`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:48:00 12/10/2014 
// Design Name: 
// Module Name:    Cnt2 
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
module Cnt2(
	clk,		// system clock
	reset,		// system reset
	clear,		// clear count
	maxValue,	// maximum count
	loadValue, // load count 
	go,		// enable count
	load, // enable load
	count		// count value
);

parameter SIZECOUNT = 12;

// Input(s)
input 				clk; 
input				reset;
input 				go;
input				clear;
input           load;
input [SIZECOUNT-1 : 0]    loadValue;
input [SIZECOUNT-1 : 0]		maxValue;
// Output(s)
output [SIZECOUNT-1 : 0]	count;
// Wire(s) and Reg(s)
wire  				clk;
wire				reset;
wire 				go;
wire				clear;
wire           load;
wire [SIZECOUNT-1 : 0]    loadValue;
wire [SIZECOUNT-1 : 0]		maxValue;
reg [SIZECOUNT-1 : 0] 		count;


// Count Update
always @ (posedge clk or posedge reset)
	if (reset) 
		count <= 0;
	else if (clear)
		count <= 0;
	else if (load)
      count <= loadValue;	
	else if (count==maxValue)
		count <= count;	
	else if (go)
		count <= count+1;

endmodule
