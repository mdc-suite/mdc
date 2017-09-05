// ----------------------------------------------------------------------------
//
// Multi-Dataflow Composer tool - Platform Composer
// Burst Counter module 
// Date: 2014/04/30 12:15:58
//
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Interface
// ----------------------------------------------------------------------------
module Burst_Counter(
	clk,		// system clock
	reset,		// system reset
	go,		// enable count
	clear,		// clear count
	sizeburst,	// maximum count
	endburst	// finish count
);
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Parameter(s)
// ----------------------------------------------------------------------------
parameter SIZEBURST = 5;
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Signals
// ----------------------------------------------------------------------------
// Input(s)
input 			clk;
input			go;
input			clear;
input			reset;
input [SIZEBURST-1 : 0]	sizeburst;
// Output(s)
output	 		endburst;
// Wire(s) and Reg(s)
reg 			endburst;
reg [SIZEBURST-1 : 0] 	burst;
reg [SIZEBURST-1 : 0] 	burst_nxt;
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Body
// ----------------------------------------------------------------------------
// Count Register
always @ (posedge clk or posedge reset)
	if(reset)
		burst <= 0;
	else if (clear)
		burst <= 0;
	else 
		burst <= burst_nxt;

// Count Update
always @ (burst,go,sizeburst)
	if (burst==sizeburst)
		burst_nxt = burst;
	else if (go) 
		burst_nxt = burst+1;
	else 
		burst_nxt = burst;

// Finish Count
always @ (burst,sizeburst)
	if (burst==sizeburst) 
		endburst = 1;
	else 
		endburst = 0;
// ----------------------------------------------------------------------------
		
endmodule		
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
