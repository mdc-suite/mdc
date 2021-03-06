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
	parameter SIZE_WORD = 32,
	parameter SIZE_MEM = 256,
	parameter SIZE_ADDR = 8
)(
    input wire aclk_a,
    input wire ce_a,
	input wire rden_a,
	input wire wren_a,
	input wire [SIZE_ADDR-1 : 0] address_a,
	input wire [SIZE_WORD-1 : 0] data_in_a,
	output reg [SIZE_WORD-1 : 0] data_out_a,
    input wire aclk_b,
    input wire ce_b,
	input wire rden_b,
	input wire wren_b,
	input wire [SIZE_ADDR-1 : 0] address_b,
	input wire [SIZE_WORD-1 : 0] data_in_b,
	output reg [SIZE_WORD-1 : 0] data_out_b
);

	reg  [SIZE_WORD-1:0] ram [SIZE_MEM-1:0];
	
	always @(posedge aclk_a)
    begin
        if (ce_a)
        begin
            if (wren_a)
                ram[address_a] <= data_in_a;
            data_out_a <= ram[address_a];
        end
    end
    
    always @(posedge aclk_b)
    begin
        if (ce_b)
        begin
            if (wren_b)
                ram[address_b] <= data_in_b;
            data_out_b <= ram[address_b];
        end
    end

endmodule
