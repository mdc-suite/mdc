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
module counter#(
	parameter SIZE = 12
)(
    input wire aclk,
    input wire aresetn,
    input wire clr,
    input wire en,
    input wire [SIZE-1 : 0] max,
    output reg [SIZE-1 : 0] count,
    output wire last
);

	always@(posedge aclk or negedge aresetn)
		if(!aresetn)
			count <= 0;
		else
			if(clr)
				count <= 0;
			else
				if(en)
					if(count < max)
						count <= count +1;
					else
						count <= 0;
				else
					count <= count;
				
	assign last = (!clr) && (count == max);

endmodule
