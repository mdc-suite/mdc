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
    input wire last,
    input wire full,
    output reg en,
    output reg rden,
    output reg wr,
    output reg done
);

    parameter   IDLE = 3'd0,
                FIRST = 3'd1,
                WORK = 3'd2,
                LAST = 3'd3,
                DONE = 3'd4;

    reg [2:0]  state, state_nxt;
    
    always@(posedge aclk or negedge aresetn)
        if(!aresetn)
            state <= IDLE;
        else
            state <= state_nxt;
            
    always@(state or start or full or last)
        case(state)
            IDLE:   if(start)
                        state_nxt = FIRST;
                    else
                        state_nxt = IDLE;
			FIRST:  if(!full)
            			if(!last)
                			state_nxt = WORK;
                	 	else
                    		state_nxt = LAST;
                    else
                        state_nxt = FIRST; 
         	WORK:   if(!full)
						if(last)
							state_nxt = LAST;
								else
							state_nxt = WORK;
				else
						state_nxt = WORK;
        	LAST:	if(!full)
        	           state_nxt = DONE;
        	        else
        	           state_nxt = LAST;
        	DONE:	if(last)
        				state_nxt = DONE;
                    else
                        state_nxt = IDLE; 
            default:    state_nxt = IDLE;
        endcase
                    
    always@(state or full or last)
        case(state)
            IDLE:       {en,rden,wr,done} = {1'b0,          1'b0,1'b0, 1'b0};
            FIRST:      {en,rden,wr,done} = {!full && !last,1'b1,1'b0, 1'b0};
            WORK:       {en,rden,wr,done} = {!full && !last,!full,!full,1'b0};
            LAST:       {en,rden,wr,done} = {1'b0,          !full,!full, 1'b0};
            DONE:		{en,rden,wr,done} = {1'b0,          1'b0,1'b0, 1'b1};
            default:    {en,rden,wr,done} = 4'b0000;
        endcase
               
endmodule
