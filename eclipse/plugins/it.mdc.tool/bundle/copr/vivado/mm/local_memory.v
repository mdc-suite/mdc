`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/20/2016 01:08:35 PM
// Design Name: 
// Module Name: local_memory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module local_memory #(
	parameter SIZE_MEM = 256,
	parameter SIZE_ADDR = 8
)(
    input wire aclk,
    input wire ce_a,
	input wire rden_a,
	input wire wren_a,
	input wire [SIZE_ADDR-1 : 0] address_a,
	input wire [31 : 0] data_in_a,
	output reg [31 : 0] data_out_a,
	input wire rden_b,
	input wire wren_b,
	input wire [SIZE_ADDR-1 : 0] address_b,
	input wire [31 : 0] data_in_b,
	output reg [31 : 0] data_out_b
);

	reg  [31:0] ram [0 : SIZE_MEM-1];
     
    always @( posedge aclk )
    begin
     if (ce_a)
	     if (wren_a)
	       begin
	         ram[address_a] <= data_in_a;
	       end   
    end    
	      
    always @( posedge aclk )
    begin
     if (ce_a)
	     if (rden_a)
	       begin
	         data_out_a <= ram[address_a];
	       end   
    end
   
    always @( posedge aclk )
    begin
     if (wren_b)
       begin
         ram[address_b] <= data_in_b;
       end   
    end    
	      
    always @( posedge aclk )
    begin
     if (rden_b)
       begin
         data_out_b <= ram[address_b];
       end   
    end

endmodule
