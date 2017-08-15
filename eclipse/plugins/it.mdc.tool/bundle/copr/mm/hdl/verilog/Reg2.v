`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:29:52 12/11/2014 
// Design Name: 
// Module Name:    Reg2 
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

module Reg2 (
	clk,			// system clock
	enable,			// enable
	reset,			// system reset
	clear, 			// internal clear
	datain,			// input data
	dataout			// output data
);

// Module Parameter(s)
parameter SIZEDATA = 5;

// Module Signals
// ----------------------------------------------------------------------------
// Input(s)
input 			clk;
input			reset;
input 			enable;
input			clear;
input [SIZEDATA-1 : 0]	datain;
// Output(s)
output [SIZEDATA-1 : 0] dataout;
// Wire(s) and Reg(s)
wire  			clk;
wire			reset;
wire 			enable;
wire			clear;
wire [SIZEDATA-1 : 0] 	datain;
reg [SIZEDATA-1 : 0] 	dataout;

// Register
always @ (posedge clk or posedge reset) begin
	if (reset) 
		dataout <= 0;
	else if (clear) 
		dataout <=0;
	else if(enable) 
		dataout <= datain;
end



endmodule
