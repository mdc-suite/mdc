`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/20/2016 01:08:56 PM
// Design Name: 
// Module Name: back_end
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
module back_end(
    input wire aclk,
    input wire aresetn,
    input wire start,
    input wire last,
    input wire wr,
    output reg en,
    output reg wren,
    output reg full,
    output reg done
);

    parameter   IDLE = 2'd0,
                WORK = 2'd1,
                DONE = 2'd2;

    reg [1:0]  state, state_nxt;
    
    always@(posedge aclk or negedge aresetn)
        if(!aresetn)
            state <= IDLE;
        else
            state <= state_nxt;
            
    always@(state or start or last or wr)
        case(state)
            IDLE:   if(start)
                        state_nxt = WORK;
                    else
                        state_nxt = IDLE;
            WORK:   if(last && wr)
                        state_nxt = DONE;
                    else
            			state_nxt = WORK;
			DONE:	if(last)
						state_nxt = DONE;
					else
						state_nxt = IDLE;
            default:    state_nxt = IDLE;
        endcase
                    
    always@(state or wr or last)
        case(state)
            IDLE:       {en,wren,full,done} = 4'b0010;
            WORK:       {en,wren,full,done} = {wr && !last,wr,1'b0,1'b0};
            DONE:		{en,wren,full,done} = 4'b0001;
            default:    {en,wren,full,done} = 4'b0000;
        endcase
               
endmodule