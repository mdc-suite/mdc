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
    input wire done,
    input wire send,
    output reg en,
    output reg wren,
    output reg rdy,
    output reg ack
);

    parameter   IDLE = 1'b0,
                WORK = 1'b1;

    reg  state, state_nxt;
    
    always@(posedge aclk or negedge aresetn)
        if(!aresetn)
            state <= IDLE;
        else
            state <= state_nxt;
            
    always@(state or start or done)
        case(state)
            IDLE:   if(start)
                        state_nxt = WORK;
                    else
                        state_nxt = IDLE;
            WORK:   if(start && !done)
                        state_nxt = WORK;
                    else
                        state_nxt = IDLE; 
            default:    state_nxt = IDLE;
        endcase
                    
    always@(state or send)
        case(state)
            IDLE:       {en,wren,rdy,ack} = 4'b0000;
            WORK:       {en,wren,rdy,ack} = {send,send,1'b1,send};
            default:    {en,wren,rdy,ack} = 4'b0000;
        endcase
               
endmodule
