// ----------------------------------------------------------------------------
//
// Multi-Dataflow Composer tool - Platform Composer
// Pointer Counter module 
// Date: 2014/04/30 12:15:58
//
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Interface
// ----------------------------------------------------------------------------
module b_counter(
	c_out,
	c_reset,
	c_clk,
	en
);
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Parameter(s)
// ----------------------------------------------------------------------------
parameter c_width = 4; 			//counter width
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Signals
// ----------------------------------------------------------------------------
// Input(s)
input 			c_reset;
input			c_clk;
input			en;
// Output(s)
output [c_width-1 : 0] 	c_out;
// Wire(s) and Reg(s)
reg [c_width-1 : 0] 	c_out;
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Body
// ----------------------------------------------------------------------------
always @(posedge c_clk or posedge c_reset)
	if (c_reset)
 		c_out <= 0;
	else if (en)
 		c_out <= c_out + 1;
// ----------------------------------------------------------------------------
		
endmodule		
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
