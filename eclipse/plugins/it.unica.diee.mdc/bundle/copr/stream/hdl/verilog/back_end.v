`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:08:34 02/14/2015 
// Design Name: 
// Module Name:    back_end 
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
module back_end(
	 clk,
	 rst,
	 FSL_M_WRITE,
	 FSL_M_FULL,
	 clear,
	 size,
	 endsend,
	 OUT_send,
	 IN_ack,
	 IN_rdy
	);
	
parameter SIZECOUNT = 12;				
parameter SIZESIGNAL = 1;	  
	 
input wire clk;
input wire rst;
output wire FSL_M_WRITE;
input wire FSL_M_FULL;
input wire clear;
input wire [SIZECOUNT-1:0] size;
output wire endsend;
input wire OUT_send;
output wire IN_ack;
output wire IN_rdy;

wire enable_cnt;
wire [SIZECOUNT-1:0] count;

// interface logic
assign IN_rdy=!FSL_M_FULL;
assign IN_ack=FSL_M_WRITE;
assign enable_cnt=!endsend;
assign FSL_M_WRITE=OUT_send && !FSL_M_FULL && enable_cnt;

  // port counter
      s_cnt #(
      .SIZECOUNT(SIZECOUNT)  )
		size_counter(
		.clk(clk),
		.rst(rst),
		.go(FSL_M_WRITE),
		.e_cnt(enable_cnt),
		.clear(clear),
		.count(count)
		);
		
   // endcount generator
		s_logic #(
      .SIZECOUNT(SIZECOUNT)  )		
      Size_logic(
		.count(count),
		.size(size),
		.endcount(endsend)
		);

endmodule
