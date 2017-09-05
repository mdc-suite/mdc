`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:59:49 02/13/2015 
// Design Name: 
// Module Name:    cfg_FSM 
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
module cfg_FSM(
    clk,
	 reset,	
    exists,
	 start,
	 DC,	
	 endldcr,
	 RD,
	 write
	);

// FSM states
parameter IDLE=0;
parameter RD_FIFO=1; 
parameter WR_CFG=2;

input wire clk;
input wire reset;
input wire exists;
input wire start;
input wire DC;
input wire endldcr;
output reg RD;
output reg write;

reg [1:0] state,state_nxt;


// State Register
always @ (posedge clk or posedge reset)
	if (reset) 
		state<=IDLE;
	else 
		state<=state_nxt;

// State Update
always @ (state or exists or start or DC)
	case(state)		
	    IDLE: if((exists)&&(!start)&&(DC))
	             state_nxt=RD_FIFO;
				 else 	 
	             state_nxt=IDLE;
		 RD_FIFO: state_nxt=WR_CFG;
       WR_CFG: if((exists)&(!start))
	               state_nxt=WR_CFG;
					else 	 
	               state_nxt=IDLE;	
	    default: state_nxt=IDLE;
	endcase
	
// Mealy Outputs
always @ (state or endldcr or start)
	case(state)	
	    IDLE:    begin
		          RD=0;
					 write=0;
                end		
       RD_FIFO: begin
		          RD=1;
					 write=0;
                end	
       WR_CFG:  begin
		          RD=((!start)&&(!endldcr));
					 write=!start;
                end	
       default: begin
		          RD=0;
					 write=0;
                end	
   endcase
endmodule
