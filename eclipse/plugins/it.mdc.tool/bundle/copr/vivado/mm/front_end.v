`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/20/2016 01:08:35 PM
// Design Name: 
// Module Name: front_end
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
module front_end(
    input wire aclk,
    input wire aresetn,
    input wire start,
    input wire done,
    input wire full,
    output reg en,
    output reg rden,
    output reg wr
);

    parameter   IDLE = 2'd0,
                WAIT = 2'd1,
                WORK = 2'd2,
                LAST = 2'd3;

    reg [1:0]  state, state_nxt;
    
    always@(posedge aclk or negedge aresetn)
        if(!aresetn)
            state <= IDLE;
        else
            state <= state_nxt;
            
    always@(state or start or full or done)
        case(state)
            IDLE:   if(start)
                        state_nxt = WAIT;
                    else
                        state_nxt = IDLE;
            WAIT:   if(!start)
                        state_nxt = IDLE;
                    else if(!full && !done)
                        state_nxt = WORK;
                    else
                        state_nxt = WAIT; 
             WORK:   if(!start)
                        state_nxt = IDLE;
                     else 
						if(!full)
							if(done)
								state_nxt = LAST;
							else
								state_nxt = WORK;
						else
							state_nxt = WAIT;
        	LAST:	if(!start)
                        state_nxt = IDLE;
                    else
                        state_nxt = WAIT; 
            default:    state_nxt = IDLE;
        endcase
                    
    always@(state or full or done)
        case(state)
            IDLE:       {en,rden,wr} = {1'b0,1'b0,1'b0};
            WAIT:       {en,rden,wr} = {!full && !done,1'b1,1'b0};
            WORK:       {en,rden,wr} = {!full && !done,1'b1,!full};
            LAST:       {en,rden,wr} = {1'b0,1'b1,1'b1};
            default:    {en,rden,wr} = 3'b000;
        endcase
               
endmodule