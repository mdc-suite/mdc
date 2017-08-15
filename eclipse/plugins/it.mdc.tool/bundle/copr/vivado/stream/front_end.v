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
    input wire tvalid,
    input wire rdy,
    input wire ack,
    output reg tready,
    output reg send
);

    parameter   IDLE = 1'b0,
                WORK = 1'b1;

    reg  state, state_nxt;
    
    always@(posedge aclk or negedge aresetn)
        if(!aresetn)
            state <= IDLE;
        else
            state <= state_nxt;
            
    always@(state or start)
        case(state)
            IDLE:   if(start)
                        state_nxt = WORK;
                    else
                        state_nxt = IDLE;
            WORK:   if(start)
                        state_nxt = WORK;
                    else
                        state_nxt = IDLE; 
            default:    state_nxt = IDLE;
        endcase
                    
    always@(state or tvalid or ack or rdy)
        case(state)
            IDLE:       {tready,send} = 2'b00;
            WORK:       {tready,send} = {ack,tvalid&&rdy};
            default:    {tready,send} = 2'b00;
        endcase
               
endmodule