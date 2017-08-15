// ----------------------------------------------------------------------------
//
// Multi-Dataflow Composer tool - Platform Composer
// Dual Port Memory module 
// Date: 2014/04/30 12:15:58
//
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Interface
// ----------------------------------------------------------------------------
module DualPortMemory(
	clk1,		// system clock port 1
	address1,	// address port 1
	enable1,	// enable port 1
	write1,		// write enable port 1
	datain1,	// input data port 1
	clk2,		// system clock port 2
	dataout1,	// output data port 2
	address2,	// address port 2
	enable2,	// enable port 2
	write2,		// write enable port2
	datain2,	// input data port 2
	dataout2	// output data port 2
);
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Parameter(s)
// ----------------------------------------------------------------------------
parameter SIZEDATA = 32;
parameter SIZEADDRESS = 16;
parameter NWORDS = 2**SIZEADDRESS;
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Module Signals
// ----------------------------------------------------------------------------
// Input(s)
input 				clk1;
input				clk2;
input 				enable1;
input				enable2;
input				write1;
input				write2;
input [SIZEADDRESS-1 : 0]	address1;
input [SIZEADDRESS-1 : 0]	address2;
input [SIZEDATA-1 : 0] 		datain1;
input [SIZEDATA-1 : 0] 		datain2;
// Output (s)
output reg [SIZEDATA-1 : 0] 	dataout1;
output reg [SIZEDATA-1 : 0] 	dataout2;
// Memory
reg [SIZEDATA-1:0] memory [NWORDS-1:0];
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Body
// ----------------------------------------------------------------------------
// Write Port 1
always @ (posedge clk1)
	if(enable1 && write1)
		memory[address1] <= datain1;

// Write Port 2
always @ (posedge clk2)
	if (enable2 && write2)
		memory[address2] <= datain2;

// Read Port 1
always @ (posedge clk1)
	if (enable1)
		dataout1 <= memory[address1];

// Read Port 2
always @ (posedge clk2)
	if (enable2)
	dataout2 <= memory[address2];
// ----------------------------------------------------------------------------
		
endmodule		
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
