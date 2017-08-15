`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:16:57 02/14/2015 
// Design Name: 
// Module Name:    front_end 
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
module front_end(
    clk,
	 rst, 
	 FSL_S_READ,
	 FSL_S_EXISTS,
	 clear,
	 rd_FSMctrl,
	 start,
	 size,
	 sizeburst,
	 IN_send,
	 OUT_rdy,
	 IN_count
	);
	  				
parameter SIZECOUNT = 12;			
parameter SIZEBURST = 8;	
parameter SIZESIGNAL = 1;	 

input wire clk;
input wire rst;
output wire FSL_S_READ;
input wire FSL_S_EXISTS;
input wire clear;
input wire rd_FSMctrl;
input wire start;
input wire [SIZECOUNT-1:0] size;
input wire [SIZEBURST-1:0] sizeburst;
output wire IN_send;
input wire OUT_rdy;
output wire [SIZEBURST-1:0] IN_count;


wire rd_FSMin;
wire endburst_fe;
wire endsend_fe;
wire [SIZECOUNT-1:0] count;
wire enable_cnt;
	
assign enable_cnt=!endsend_fe;
assign FSL_S_READ = rd_FSMin || rd_FSMctrl;
	
	// Input Finite State Machine
	fsmIN_RDmem R_fsm (
		.clk(clk),					// system clock
		.rst(rst),					// system reset
		.start(start),				// start computation
		.exists(FSL_S_EXISTS),   // exists data from FSL slave
		.OUT_rdy(OUT_rdy), 			// datapath ready
		.endburst(endburst_fe),		// end burst
		.endsend(endsend_fe),			// end size
		.read(rd_FSMin),	// enable memory
		.send(IN_send),			// send data
		.count(go_fe)				// go counter
	);	
	
	s_cnt #(
      .SIZECOUNT(SIZECOUNT)  )
		size_counter(
		.clk(clk),
		.rst(rst),
		.go(go_fe),
		.e_cnt(enable_cnt),
		.clear(clear),
		.count(count)
		);
	
   b_logic #(
		.SIZEBURST(SIZEBURST),
      .SIZECOUNT(SIZECOUNT)  )	
		Burst_logic(
		.count(count),
		.sizeburst(sizeburst),
		.endburst(endburst_fe)
		);
		
	s_logic #(
      .SIZECOUNT(SIZECOUNT)  )		
      Size_logic(
		.count(count),
		.size(size),
		.endcount(endsend_fe)
		);

// in_count=2^sizeburst	
assign IN_count = 1<<sizeburst; 
	


endmodule
