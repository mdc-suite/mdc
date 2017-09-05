`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:03:01 02/21/2015 
// Design Name: 
// Module Name:    s_cnt 
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
module s_cnt(
    clk,
	 rst,
	 go,
	 e_cnt,
	 clear,
	 count
	 );
	 
parameter SIZECOUNT=12;

input wire clk;
input wire rst;
input wire go;
input wire e_cnt;
input wire clear;
output reg [SIZECOUNT-1:0] count;

reg [SIZECOUNT-1:0] count_nxt;

always @(posedge clk or posedge rst) begin
       if (rst)
		 count<=0;
		 else count<=count_nxt;
		 end

always @(clear or e_cnt or go or count) begin
       if(clear)
          count_nxt<=0;
       else if(!e_cnt)	 
	            count_nxt<=count;
			   else if(go)
                   count_nxt<=count+1;
                 else count_nxt<=count;
        end	 						 


endmodule
